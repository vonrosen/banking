use namespace HH\Lib\{C, Str};
use function Banking\Config\get_routed_methods_map_async;
use function Banking\Utils\instance;
use type Banking\Database\MigrationRunner;

<<__EntryPoint>>
async function main_async(): Awaitable<void> {
  // Initialize the Autoloader
  require_once(__DIR__.'/../vendor/autoload.hack');
  \Facebook\AutoloadMap\initialize();

  // Run database migrations
  await MigrationRunner::runMigrationsAsync();

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
  $controller = instance($controller_name);
  await $controller->$method_name();
}
