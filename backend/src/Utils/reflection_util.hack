namespace Banking\Utils;

use namespace HH\Lib\Str;

function instance(string $className): dynamic {
    if (!\class_exists($className)) {
        throw new \Exception(Str\format('Class: %s does not exist', $className));
    }
    $rc = new \ReflectionClass($className);
    if (!$rc->isInstantiable()) {
        throw new \Exception(Str\format('Could not instantiate class: %s', $className));
    }
    return $rc->newInstance();
}