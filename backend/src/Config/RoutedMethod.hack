namespace Banking\Config;

type RoutedMethod = shape(
  'controller' => string,
  'method' => string,
  'pattern' => string,
  'regex' => string,
  'params' => vec<string>,
);