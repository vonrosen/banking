namespace Banking\Redis;

final class RedisConfig {
  public function getHost(): string {
    $host = \getenv('REDIS_HOST');
    return $host is string ? $host : 'redis';
  }

  public function getPort(): int {
    $port = \getenv('REDIS_PORT');
    return $port is string ? (int)$port : 6379;
  }

  public function getPassword(): ?string {
    $password = \getenv('REDIS_PASSWORD');
    return $password is string && $password !== '' ? $password : null;
  }

  public function getDatabase(): int {
    $database = \getenv('REDIS_DATABASE');
    return $database is string ? (int)$database : 0;
  }

  public function getTimeoutSeconds(): float {
    $timeout = \getenv('REDIS_TIMEOUT');
    return $timeout is string ? (float)$timeout : 5.0;
  }
}
