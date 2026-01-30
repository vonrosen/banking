use namespace HH\Lib\{C, Str};
use function Banking\Utils\{get_routed_methods_map_async, match_route};
use type Banking\Database\MigrationRunner;
use type Banking\Container\AppContainer;
use type Banking\Config\RoutedMethod;

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

  $routed_methods = get_routed_methods_map_async();
  $match_result = match_route($method, $path, $routed_methods);

  if ($match_result === null) {
    \http_response_code(404);
    echo \json_encode(shape(
      'error' => 'Not Found',
    ));
    return;
  }

  \HH\global_set('PATH_PARAMS', $match_result['params']);

  $routed_method = $match_result['route'];
  $controller_name = $routed_method['controller'];
  $method_name = $routed_method['method'];
  /* HH_FIXME[4110] Using string class name with container->get() */
  $controller = $container->get($controller_name);
  await $controller->$method_name();
}
