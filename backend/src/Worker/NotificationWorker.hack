namespace Banking\Worker;

use type Banking\Redis\IRedisClient;
use type Banking\Clients\IBankingClient;
use type Banking\Repositories\IAnalysisRepository;
use type Banking\StateMachine\AnalysisStatusStateMachine;
use type Banking\Models\AnalysisStatus;
use type Banking\Services\RedisStreamService;
use type HackLogging\LogLevel;

final class NotificationWorker extends BaseWorker {

  public function __construct(
    private IRedisClient $redisClient,
  ) {
    parent::__construct($redisClient);
  }

    protected async function processMessageAsync(
        string $id,
        dict<string, string> $fields,
    ): Awaitable<void> {
        //send server side effects to client here
        await $this->logger->writeAsync(
            LogLevel::INFO,
            'Processing notification message: '.\json_encode($fields),
            dict[],
        );

    }
}