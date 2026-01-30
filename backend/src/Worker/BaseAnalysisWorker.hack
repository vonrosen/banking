namespace Banking\Worker;

use type Banking\Models\AnalysisStatus;
use type Banking\Redis\IRedisClient;
use type Banking\Repositories\IAnalysisRepository;
use type Banking\StateMachine\AnalysisStatusStateMachine;
use type Banking\Services\RedisStreamService;
use namespace HH\Lib\Str;
use type HackLogging\Logger;
use type Banking\Logging\LoggerFactory;
use type HackLogging\LogLevel;

abstract class BaseAnalysisWorker extends BaseWorker {
    const string ANALYSIS_CACHE_PREFIX = 'analysis:';
    const int ANALYSIS_CACHE_TTL_SECONDS = 3600;

    abstract public function getAnalysisStatus(): AnalysisStatus;
    abstract protected function processMessageAsync(
        string $messageId,
        dict<string, string> $fields,
    ): Awaitable<void>;

    protected Logger $logger;

    public function __construct(
        private IRedisClient $redisClient,
        private IAnalysisRepository $analysisRepository,
        private AnalysisStatusStateMachine $statusStateMachine,
        private RedisStreamService $redisStreamService,
    ) {
        parent::__construct($redisClient);
        $this->logger = LoggerFactory::getLogger(static::class);
    }

    <<__Override>>
    protected function getStreamName(): string {
        return $this->redisStreamService
            ->getStreamName($this->getAnalysisStatus()) as nonnull;
    }

    <<__Override>>
    protected async function doProcessMessageAsync(
        string $id,
        dict<string, string> $fields,
    ): Awaitable<void> {
        $analysisId = $fields['analysis_id'];

        await $this->logger->writeAsync(
            LogLevel::INFO,
            Str\format(
                '[%s] Processing message %s for analysis %s',
                \date('Y-m-d H:i:s'),
                $id,
                $analysisId,
            ),
            dict[],
        );

        $analysis = await $this->analysisRepository->updateAnalysisStatus(
            $analysisId,
            (string)$this->getAnalysisStatus(),
        );

        $cacheKey = self::ANALYSIS_CACHE_PREFIX.$analysisId;
        $this->redisClient->setex(
            $cacheKey,
            self::ANALYSIS_CACHE_TTL_SECONDS,
            \json_encode(shape(
                'id' => $analysis['id'],
                'user_id' => $analysis['user_id'],
                'status' => $analysis['status'],
                'llm_analysis_result' => $analysis['llm_analysis_result'],
                'provider_policy_details' =>
                    $analysis['provider_policy_details'],
                'error_message' => $analysis['error_message'],
                'error_step' => $analysis['error_step'],
                'retry_count' => $analysis['retry_count'],
                'created_at' => $analysis['created_at'],
                'updated_at' => $analysis['updated_at'],
            )),
        );

        await parent::doProcessMessageAsync($id, $fields);

        $nextStatus = $this->statusStateMachine
            ->getNextStatus($this->getAnalysisStatus()) as nonnull;
        $nextStreamName = $this->redisStreamService->getStreamName($nextStatus);

        if ($nextStreamName === null) {
            $analysis = await $this->analysisRepository
                ->updateAnalysisStatus($analysisId, (string)$nextStatus);
            $cacheKey = self::ANALYSIS_CACHE_PREFIX.$analysisId;
            $this->redisClient->setex(
                $cacheKey,
                self::ANALYSIS_CACHE_TTL_SECONDS,
                \json_encode(shape(
                    'id' => $analysis['id'],
                    'user_id' => $analysis['user_id'],
                    'status' => $analysis['status'],
                    'llm_analysis_result' => $analysis['llm_analysis_result'],
                    'provider_policy_details' =>
                        $analysis['provider_policy_details'],
                    'error_message' => $analysis['error_message'],
                    'error_step' => $analysis['error_step'],
                    'retry_count' => $analysis['retry_count'],
                    'created_at' => $analysis['created_at'],
                    'updated_at' => $analysis['updated_at'],
                )),
            );
        } else {
            $this->redisClient->xadd($nextStreamName, $fields);
        }
    }

    public function getGroupName(): string {
        return 'worker_group_'.(string)$this->getAnalysisStatus();
    }
}