use namespace HH\Lib\Str;

<<__EntryPoint>>
async function main_async(): Awaitable<void> {
  // Initialize the Autoloader
  require_once(__DIR__.'/../vendor/autoload.hack');
  \Facebook\AutoloadMap\initialize();

  // Get request info
  $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
  $path = $_SERVER['REQUEST_URI'] ?? '/';

  // Remove query string if present
  $path = Str\split($path, '?')[0];

  // Set JSON content type for all responses
  \header('Content-Type: application/json');

  // Route the request
  if ($method === 'POST' && $path === '/v1/users') {
    $controller = new \Banking\Controllers\UserController();
    await $controller->createAsync();
  } else {
    \http_response_code(404);
    echo \json_encode(shape(
      'error' => 'Not Found',
    ));
  }
}
