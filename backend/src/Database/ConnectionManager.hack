namespace Banking\Database;

use namespace HH\Lib\C;

/**
 * Manages PostgreSQL connections via PgBouncer.
 * PgBouncer handles connection pooling externally.
 */
final class ConnectionManager {

  private static function createConnection(): resource {
    $connString = DatabaseConfig::getConnectionString();
    // Append a unique application_name to guarantee a distinct connection,
    // in case PGSQL_CONNECT_FORCE_NEW is not available or doesn't work as expected.
    $uniqueConnString = $connString.' application_name=query_'.\bin2hex(\random_bytes(8));

    $conn = \pg_connect($uniqueConnString);

    if ($conn === false) {
      // Redact password from connection string for logging
      $safeConnString = \preg_replace('/password=\S+/', 'password=***', $uniqueConnString) as string;
      throw new \Exception(
        'Failed to connect to PostgreSQL database. '.
        'Connection string: '.$safeConnString.'. '.
        'Check that the database server is running and accessible.'
      );
    }

    return $conn;
  }

  public static async function queryAsync(string $sql, vec<mixed> $params = vec[]): Awaitable<vec<dict<string, mixed>>> {
    // Create a dedicated connection for this query to allow concurrent async queries.
    // PgBouncer handles connection pooling externally.
    $conn = self::createConnection();

    // Log the SQL being executed (truncate long queries)
    $logSql = \strlen($sql) > 200 ? \substr($sql, 0, 200).'...' : $sql;
    \error_log('[DB] Executing: '.\preg_replace('/\s+/', ' ', $logSql) as string);

    try {
      if (C\is_empty($params)) {
        $sent = \pg_send_query($conn, $sql);
      } else {
        $sent = \pg_send_query_params($conn, $sql, $params);
      }

      if ($sent === false) {
        $error = \pg_last_error($conn);
        throw new \Exception('Failed to send query: '.$error);
      }

      while (\pg_connection_busy($conn)) {
        await \HH\Asio\usleep(100);
      }

      $result = \pg_get_result($conn);
      if ($result === false) {
        $error = \pg_last_error($conn);
        \error_log('[DB] Query failed (no result): '.$error);
        throw new \Exception('Query failed (no result): '.$error);
      }

      // Check for query execution errors
      $resultStatus = \pg_result_status($result);
      $resultError = \pg_result_error($result);
      \error_log('[DB] Result status: '.$resultStatus.', error: '.($resultError ?: 'none'));

      if ($resultError !== false && $resultError !== '') {
        throw new \Exception('Query failed: '.$resultError);
      }

      return self::fetchAll($result);
    } finally {
      \pg_close($conn);
    }
  }

  private static function fetchAll(resource $result): vec<dict<string, mixed>> {
    $rows = vec[];
    while (true) {
      $row = \pg_fetch_assoc($result);
      if ($row === false) {
        break;
      }
      $rows[] = dict($row);
    }
    return $rows;
  }
}
