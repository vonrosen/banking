namespace Banking\Database;

use namespace HH\Lib\C;

/**
 * Manages PostgreSQL connections via PgBouncer.
 * PgBouncer handles connection pooling externally.
 */
final class ConnectionManager {
  private static ?resource $connection = null;

  public static function getConnection(): resource {
    if (self::$connection === null || !\pg_ping(self::$connection)) {
      $connString = DatabaseConfig::getConnectionString();
      $conn = \pg_connect($connString);

      if ($conn === false) {
        throw new \Exception('Failed to connect to PostgreSQL database');
      }

      self::$connection = $conn;
    }

    return self::$connection;
  }

  /**
   * Execute a query with optional parameters.
   */
  public static function query(string $sql, vec<mixed> $params = vec[]): resource {
    $conn = self::getConnection();

    if (C\is_empty($params)) {
      $result = \pg_query($conn, $sql);
    } else {
      $result = \pg_query_params($conn, $sql, $params);
    }

    if ($result === false) {
      $error = \pg_last_error($conn);
      throw new \Exception('Query failed: '.$error);
    }

    return self::fetchAll($result);
  }


  private static function fetchAll(resource $result): vec<dict<string, mixed>> {
    $rows = vec[];
    while (($row = \pg_fetch_assoc($result)) !== false) {
      $rows[] = dict($row);
    }
    return $rows;
  }
}
