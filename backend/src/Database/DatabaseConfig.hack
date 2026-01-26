namespace Banking\Database;

final class DatabaseConfig {
  public function getConnectionString(): string {
    $host = \getenv('DB_HOST');
    $host = $host is string ? $host : 'localhost';

    $user = \getenv('DB_USER');
    $user = $user is string ? $user : 'myuser';

    $password = \getenv('DB_PASSWORD');
    $password = $password is string ? $password : 'mypass';

    $dbname = \getenv('DB_NAME');
    $dbname = $dbname is string ? $dbname : 'banking';

    $port = \getenv('DB_PORT');
    $port = $port is string ? $port : '5432';

    return \sprintf(
      'host=%s port=%s dbname=%s user=%s password=%s',
      $host,
      $port,
      $dbname,
      $user,
      $password,
    );
  }
}
