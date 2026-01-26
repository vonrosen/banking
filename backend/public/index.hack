use namespace HH\Lib\{C, Str};
use function Banking\Utils\get_routed_methods_map_async;
use type Banking\Database\MigrationRunner;
use type Banking\Container\AppContainer;

<<__EntryPoint>>
async function main_async(): Awaitable<void> {
  // Initialize the Autoloader
  require_once(__DIR__.'/../vendor/autoload.hack');
  \Facebook\AutoloadMap\initialize();

  $container = await AppContainer::getAsync();

  // Run database migrations
  $migrationRunner = $container->get(MigrationRunner::class);
  await $migrationRunner->runMigrationsAsync();

  // Get request info
  $server = \HH\global_get('_SERVER') as dict<_, _>;
  $method = idx($server, 'REQUEST_METHOD', 'GET') as string;
  $path = idx($server, 'REQUEST_URI', '/') as string;

  // Remove query string if present
  $path = Str\split($path, '?')[0];

  // Set JSON content type for all responses
  \header('Content-Type: application/json');

  $routed_methods = await get_routed_methods_map_async();

  $key = Str\format("%s:%s", Str\uppercase($method), $path);

  if (!C\contains_key($routed_methods, $key)) {
    \http_response_code(404);
    echo \json_encode(shape(
      'error' => 'Not Found',
    ));
    return;
  }
  $routed_method = $routed_methods[$key];
  $controller_name = $routed_method['controller'];
  $method_name = $routed_method['method'];
  /* HH_FIXME[4110] Using string class name with container->get() */
  $controller = $container->get($controller_name);
  await $controller->$method_name();
}
