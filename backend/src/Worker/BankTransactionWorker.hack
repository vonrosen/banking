namespace Banking\Worker;

use namespace HH\Lib\Str;
use type Banking\Redis\IRedisClient;
use type Banking\Clients\BankingClient;
use type Banking\Logging\LoggerFactory;
use type HackLogging\Logger;
use type Banking\Repositories\IAnalysisRepository;
use type Banking\StateMachine\InsuranceAnalysisStatusStateMachine;
use type Banking\Models\InsuranceAnalysisStatus;
use type HackLogging\LogLevel;

final class BankTransactionWorker implements Worker {
  const string STREAM_NAME = 'insurance:get_bank_transactions';
  const string GROUP_NAME = 'bank_transaction_workers';

  private string $consumerName;
  private Logger $logger;

  public function __construct(
    private IRedisClient $redisClient,
    private BankingClient $bankingClient,
    private IAnalysisRepository $analysisRepository,
    private InsuranceAnalysisStatusStateMachine $statusStateMachine,
  ) {
    $this->consumerName = 'worker_'.\getmypid().'_'.\uniqid();
    $this->logger = LoggerFactory::getLogger('BankTransactionWorker');
  }

  public function getStepStatus(): InsuranceAnalysisStatus {
    return InsuranceAnalysisStatus::ANALYZING_TRANSACTIONS;
  }

  public async function run(): Awaitable<void> {
    await $this->logger->writeAsync(LogLevel::INFO, Str\format('BankTransactionWorker started (consumer: %s)', $this->consumerName), dict[]);

    $this->redisClient->xgroupCreate(
      self::STREAM_NAME,
      self::GROUP_NAME,
      '0',
      true,
    );

    while (true) {
      $entries = $this->redisClient->xreadgroup(
        self::GROUP_NAME,
        $this->consumerName,
        vec[self::STREAM_NAME],
        10,
        5000,
      );

      foreach ($entries as $entry) {
        foreach ($entry['messages'] as $message) {
          await $this->processMessageAsync($message['id'], $message['fields']);

          $this->redisClient->xack(
            self::STREAM_NAME,
            self::GROUP_NAME,
            vec[$message['id']],
          );
        }
      }
    }
  }

  private async function processMessageAsync(string $id, dict<string, string> $fields): Awaitable<void> {
    $log = \sprintf(
      "[%s] Processing message %s: %s",
      \date('Y-m-d H:i:s'),
      $id,
      \json_encode($fields),
    );
    await $this->logger->writeAsync(LogLevel::INFO, $log, dict[]);

    await $this->analysisRepository->updateAnalysisStatus(
      $fields['analysis_id'],
      (string)$this->getStepStatus(),
    );    

    $transactions = vec[];
    foreach ($this->bankingClient->getTransactionsAsync($fields['bank_login_token']) await as $transaction) {
      $transactions[] = $transaction;
    }

    await $this->analysisRepository->updateAnalysisTransactionData(
      $fields['analysis_id'],
      \json_encode($transactions) as string,
    );

    $nextStatus = $this->statusStateMachine->getNextStatus($this->getStepStatus()) as nonnull;

    $this->redisClient->xadd(
      $nextStatus['stream'] as nonnull,
      $fields,
    );
  }
}
