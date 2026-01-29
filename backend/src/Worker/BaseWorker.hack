namespace Banking\Worker;

use namespace HH\Lib\Str;
use type Banking\Models\AnalysisStatus;
use type Banking\Redis\IRedisClient;
use type Banking\Repositories\IAnalysisRepository;
use type Banking\StateMachine\AnalysisStatusStateMachine;
use type Banking\Services\RedisStreamService;
use type HackLogging\Logger;
use type Banking\Logging\LoggerFactory;
use type HackLogging\LogLevel;

abstract class BaseWorker {
    abstract protected function processMessageAsync(string $messageId, dict<string, string> $fields): Awaitable<void>;

    protected Logger $logger;

    public function __construct(
        private IRedisClient $redisClient,
    ) {
        $this->logger = LoggerFactory::getLogger(static::class);
    }

    protected async function doProcessMessageAsync(
        string $id,
        dict<string, string> $fields,
    ): Awaitable<void> {
        await $this->processMessageAsync($id, $fields);
    }

    protected function getStreamName(): string {
        return 'stream:'.static::class;
    }

    public async function run(): Awaitable<void> {
        await $this->logger->writeAsync(
            LogLevel::INFO,
            Str\format('%s started (consumer: %s)', static::class, $this->getConsumerName()),
            dict[],
        );

        $streamName = $this->getStreamName();
        
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
        return 'worker_group_'.static::class;
    }

    public function getConsumerName(): string {
        return 'worker_'.\getmypid().'_'.\uniqid();
    }
}