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

abstract class BaseWorker {
    abstract public function getAnalysisStatus(): AnalysisStatus;
    abstract protected function processMessageAsync(string $messageId, dict<string, string> $fields): Awaitable<void>;

    protected Logger $logger;

    public function __construct(
        private IRedisClient $redisClient,
        private IAnalysisRepository $analysisRepository,
        private AnalysisStatusStateMachine $statusStateMachine,
        private RedisStreamService $redisStreamService,
    ) {
        $this->logger = LoggerFactory::getLogger(static::class);
    }

    protected async function doProcessMessageAsync(
        string $id,
        dict<string, string> $fields,
    ): Awaitable<void> {
        $analysisId = $fields['analysis_id'];
        
        await $this->logger->writeAsync(
            LogLevel::INFO,
            Str\format('[%s] Processing message %s for analysis %s', \date('Y-m-d H:i:s'), $id, $analysisId),
            dict[],
        );
        
        await $this->analysisRepository->updateAnalysisStatus(
            $analysisId,
            (string)$this->getAnalysisStatus(),
        );

        await $this->processMessageAsync($id, $fields);

        $nextStatus = $this->statusStateMachine->getNextStatus($this->getAnalysisStatus()) as nonnull;
        $streamName = $this->redisStreamService->getStreamName($nextStatus);
        if ($streamName === null) {
            await $this->analysisRepository->updateAnalysisStatus(
                $analysisId,
                (string)$nextStatus,
            );
        } else {
            $this->redisClient->xadd(
                $streamName,
                $fields,
            );
        }
    }

    public async function run(): Awaitable<void> {
        await $this->logger->writeAsync(
            LogLevel::INFO,
            Str\format('%s started (consumer: %s)', static::class, $this->getConsumerName()),
            dict[],
        );

        $streamName = $this->redisStreamService->getStreamName($this->getAnalysisStatus()) as nonnull;
        
        $this->redisClient->xgroupCreate(
            $streamName,
            $this->getGroupName(),
            '0',
            true,
        );

        while (true) {
            $entries = $this->redisClient->xreadgroup(
                $this->getGroupName(),
                $this->getConsumerName(),
                vec[$streamName],
                10,
                5000,
            );

            foreach ($entries as $entry) {
                foreach ($entry['messages'] as $message) {
                    await $this->doProcessMessageAsync($message['id'], $message['fields']);

                    $this->redisClient->xack(
                        $streamName,
                        $this->getGroupName(),
                        vec[$message['id']],
                    );
                }
            }
        }
    }

    public function getGroupName(): string {
        return 'worker_group_'.(string)$this->getAnalysisStatus();
    }

    public function getConsumerName(): string {
        return 'worker_'.\getmypid().'_'.\uniqid();
    }
}