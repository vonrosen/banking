namespace Banking\Worker;

use namespace HH\Lib\Str;
use type Banking\Redis\IRedisClient;
use type Banking\Clients\IBankingClient;
use type Banking\Logging\LoggerFactory;
use type HackLogging\Logger;
use type Banking\Repositories\IAnalysisRepository;
use type Banking\StateMachine\AnalysisStatusStateMachine;
use type Banking\Models\AnalysisStatus;
use type HackLogging\LogLevel;
use type Banking\Services\RedisStreamService;

final class BankTransactionWorker extends BaseWorker {

  public function __construct(
    private IRedisClient $redisClient,
    private IBankingClient $bankingClient,
    private IAnalysisRepository $analysisRepository,
    private AnalysisStatusStateMachine $statusStateMachine,
    private RedisStreamService $redisStreamService,
  ) {
    parent::__construct(
      $redisClient,
      $analysisRepository,
      $statusStateMachine,
      $redisStreamService,
    );
  }

  public function getAnalysisStatus(): AnalysisStatus {
    return AnalysisStatus::DOWNLOADING_TRANSACTIONS;
  }

  protected async function processMessageAsync(string $id, dict<string, string> $fields): Awaitable<void> {
    $transactions = vec[];

    foreach ($this->bankingClient->getTransactionsAsync($fields['bank_login_token']) await as $transaction) {
      $transactions[] = $transaction;
    }

    await $this->analysisRepository->updateAnalysisTransactionData(
      $fields['analysis_id'],
      \json_encode($transactions) as string,
    );
  }
}
