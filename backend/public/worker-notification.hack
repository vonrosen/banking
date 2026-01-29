use type Banking\Container\AppContainer;
use type Banking\Worker\NotificationWorker;
use type Banking\Logging\LoggerFactory;
use type HackLogging\LogLevel;

<<__EntryPoint>>
async function worker_notification_main_async(): Awaitable<void> {
  require_once(__DIR__.'/../vendor/autoload.hack');
  \Facebook\AutoloadMap\initialize();

  \header('Content-Type: text/plain');

  $logger = LoggerFactory::getLogger('worker-notification');
  await $logger->writeAsync(LogLevel::INFO, 'Entry point started', dict[]);

  $container = await AppContainer::getAsync();
  $worker = $container->get(NotificationWorker::class);

  // Run the worker loop (runs forever)
  await $worker->run();
}
