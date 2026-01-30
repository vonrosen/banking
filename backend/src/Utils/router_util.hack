namespace Banking\Utils;

use namespace HH\Lib\{Dict, Regex, Str, Vec};
use type HH\Lib\Regex\Pattern;
use namespace HH\Lib\C;
use type Banking\Controllers\IController;
use type Banking\Config\RoutedMethod;
use type Banking\Attributes\Route;
use type Facebook\AutoloadMap\AutoloadMap;

function match_route(
  string $method,
  string $path,
  dict<string, RoutedMethod> $routes,
): ?shape('route' => RoutedMethod, 'params' => dict<string, string>) {
  $method = Str\uppercase($method);
  $key = Str\format('%s:%s', $method, $path);
  if (C\contains_key($routes, $key)) {
    return shape('route' => $routes[$key], 'params' => dict[]);
  }
  foreach ($routes as $route_key => $route) {
    if (!Str\starts_with($route_key, $method.':')) {
      continue;
    }
    if (C\is_empty($route['params'])) {
      continue;
    }
    $preg_matches = darray[];
    if (\preg_match_with_matches('/'.$route['regex'].'/', $path, inout $preg_matches) === 1) {
      $matches = dict[];
      foreach ($route['params'] as $param) {
        if (\array_key_exists($param, $preg_matches)) {
          $matches[$param] = (string)$preg_matches[$param];
        }
      }
      return shape('route' => $route, 'params' => $matches);
    }
  }
  return null;
}

function path_to_regex(string $path): shape('regex' => string, 'params' => vec<string>) {
  $params = vec[];
  $pattern = re"/\{([a-zA-Z_][a-zA-Z0-9_]*)\}/";
  foreach (Regex\every_match($path, $pattern) as $match) {
    $params[] = $match[1];
  }
  $regex = Regex\replace($path, $pattern, '(?P<$1>[^/]+)');
  $regex = Str\replace($regex, '/', '\\/');
  return shape('regex' => '^'.$regex.'$', 'params' => $params);
}

<<__Memoize>>
function get_routed_methods_map_async(): dict<string, RoutedMethod> {
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
      $path_info = path_to_regex($path);
      $key = Str\format('%s:%s', Str\uppercase($http_method), $path);
      $routed_methods[$key] = shape(
        'controller' => $rc->getName(),
        'method' => $method->getName(),
        'pattern' => $path,
        'regex' => $path_info['regex'],
        'params' => $path_info['params'],
      );
    }
  }
  return $routed_methods;
}