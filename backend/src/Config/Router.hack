namespace Banking\Config;

use namespace HH\Lib\{Dict, Str};
use type Banking\Interfaces\IController;

<<__Memoize>>
async function get_routed_methods_map_async(): Awaitable<dict<string, RoutedMethod>> {
  $routed_methods = dict[];
  $autoload_map = \Facebook\AutoloadMap\Generated\map_uncached();
  $controller_classes = Dict\filter_keys(
    $autoload_map['class'],
    $class_name ==> Str\starts_with(Str\lowercase($class_name), 'banking\\controllers\\'),
  );
  foreach ($controller_classes as $class_name => $_path) {
    if (!\class_exists($class_name)) {
      continue;
    }
    $rc = new \ReflectionClass($class_name);
    if (!$rc->isInstantiable()) {
      continue;
    }
    if (!$rc->implementsInterface(IController::class)) {
      continue;
    }
    foreach ($rc->getMethods() as $method) {
      $route = $method->getAttributeClass(\Banking\Attributes\Route::class);
      if ($route === null) {
        continue;
      }
      $http_method = $route->getMethod();
      $path = $route->getPath();
      $key = Str\format('%s:%s', Str\uppercase($http_method), $path);
      $routed_methods[$key] = shape(
        'controller' => $class_name,
        'method' => $method->getName(),
      );
    }
  }
  return $routed_methods;
}
