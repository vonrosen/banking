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
    $routed_path = Str\split($route_key, ":")[1];
    $params = dict[];
    $routed_path_pos = 0;
    $path_pos = 0;
    $match = true;
    while($path_pos !== null && $path_pos < Str\length($path)) {
      $routed_path_char = $routed_path[$routed_path_pos];
      if ($routed_path_char === '{') {
        $tmp_routed_path_pos = $routed_path_pos;
        $routed_path_pos = Str\search($routed_path, '}', $routed_path_pos);
        if ($routed_path_pos == null) {
          throw new \Exception(Str\format('Invalid path found: %s', $routed_path));
        }        
        $tmp_length = $routed_path_pos - ($tmp_routed_path_pos + 1);
        $param_name = Str\slice($routed_path, $tmp_routed_path_pos + 1, $tmp_length);
        $routed_path_pos++;

        $tmp_path_pos = $path_pos;
        $path_pos = Str\search($path, '/', $path_pos);
        if ($path_pos === null) {
          if ($routed_path_pos !== Str\length($routed_path)) {
            $match = false;
          }
          $tmp_length = Str\length($path) - $tmp_path_pos;
          $param_value = Str\slice($path, $tmp_path_pos, $tmp_length);        
          $params[$param_name] = $param_value;
          break;          
        }  
        $tmp_length = $path_pos - $tmp_path_pos;
        $param_value = Str\slice($path, $tmp_path_pos, $tmp_length);        
        $params[$param_name] = $param_value;
      }
      if ($routed_path[$routed_path_pos] !== $path[$path_pos]) {
        $match = false;
        break;
      }
      $path_pos++;
      $routed_path_pos++;
    }
    if ($match) {
      return shape('route' => $route, 'params' => $params);
    }
  }
  return null;
}

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
      $key = Str\format('%s:%s', Str\uppercase($http_method), $path);
      $routed_methods[$key] = shape(
        'controller' => $rc->getName(),
        'method' => $method->getName(),
      );
    }
  }
  return $routed_methods;
}