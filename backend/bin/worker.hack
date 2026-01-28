use type Banking\Container\AppContainer;
use type Banking\Worker\BankTransactionWorker;

<<__EntryPoint>>
async function worker_cli_main_async(): Awaitable<void> {
  require_once(__DIR__.'/../vendor/autoload.hack');
  \Facebook\AutoloadMap\initialize();

  $container = await AppContainer::getAsync();

  $worker = $container->get(BankTransactionWorker::class);
  await $worker->run();
}
