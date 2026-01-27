namespace Banking\Worker;

use type Banking\Redis\IRedisClient;

final class BankTransactionWorker {
  const string STREAM_NAME = 'insurance:get_bank_transactions';
  const string GROUP_NAME = 'bank_transaction_workers';

  private string $consumerName;

  public function __construct(
    private IRedisClient $redisClient,
  ) {
    // Generate unique consumer name for this worker instance
    $this->consumerName = 'worker_'.\getmypid().'_'.\uniqid();
  }

  public function run(): void {
    \file_put_contents('/tmp/worker.log', "[INFO] BankTransactionWorker started (consumer: {$this->consumerName})\n", \FILE_APPEND);

    // Create consumer group if it doesn't exist (MKSTREAM creates the stream too)
    $this->redisClient->xgroupCreate(
      self::STREAM_NAME,
      self::GROUP_NAME,
      '0',    // Start from beginning
      true,   // MKSTREAM - create stream if doesn't exist
    );

    while (true) {
      // XREADGROUP delivers each message to only ONE consumer in the group
      $entries = $this->redisClient->xreadgroup(
        self::GROUP_NAME,
        $this->consumerName,
        vec[self::STREAM_NAME],
        10,    // count
        5000,  // block for 5 seconds
      );

      foreach ($entries as $entry) {
        foreach ($entry['messages'] as $message) {
          $this->processMessage($message['id'], $message['fields']);

          // Acknowledge the message after successful processing
          $this->redisClient->xack(
            self::STREAM_NAME,
            self::GROUP_NAME,
            vec[$message['id']],
          );
        }
      }
    }
  }

  private function processMessage(string $id, dict<string, string> $fields): void {
    $log = \sprintf(
      "[%s] Processing message %s: %s\n",
      \date('Y-m-d H:i:s'),
      $id,
      \json_encode($fields),
    );
    \file_put_contents('/tmp/worker.log', $log, \FILE_APPEND);

    // TODO: Implement actual business logic here
    // - Download bank transactions
    // - Update analysis status in database
    // - Publish to next queue
  }
}
