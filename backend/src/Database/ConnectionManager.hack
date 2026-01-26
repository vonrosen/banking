namespace Banking\Database;

use namespace HH\Lib\C;
use type Banking\Logging\LoggerFactory;
use type HackLogging\Logger;
use type HackLogging\LogLevel;

final class ConnectionManager {

  private static function getLogger(): \HackLogging\Logger {
    return LoggerFactory::getLogger('ConnectionManager');
  }

  public function __construct(private DatabaseConfig $databaseConfig) {
  }

  public async function queryAsync(string $sql, vec<mixed> $params = vec[]): Awaitable<vec<dict<string, mixed>>> {
    $logger = self::getLogger();
    $conn = $this->createConnection();

    $logSql = \strlen($sql) > 200 ? \substr($sql, 0, 200).'...' : $sql;
    await $logger->writeAsync(LogLevel::INFO, 'Executing: '.\preg_replace('/\s+/', ' ', $logSql) as string, dict[]);

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
        await \HH\Asio\usleep(10);
      }

      $result = \pg_get_result($conn);
      if ($result === false) {
        $error = \pg_last_error($conn);
        await $logger->writeAsync(LogLevel::ERROR, 'Query failed (no result): '.$error, dict[]);
        throw new \Exception('Query failed (no result): '.$error);
      }

      $resultStatus = \pg_result_status($result);
      $resultError = \pg_result_error($result);
      await $logger->writeAsync(LogLevel::INFO, 'Result status: '.$resultStatus.', error: '.($resultError ?: 'none'), dict[]);

      if ($resultError !== false && $resultError !== '') {
        throw new \Exception('Query failed: '.$resultError);
      }

      return $this->fetchAll($result);
    } finally {
      \pg_close($conn);
    }
  }

  private function createConnection(): resource {
    $connString = $this->databaseConfig->getConnectionString();
    $uniqueConnString = $connString.' application_name=query_'.\bin2hex(\random_bytes(8));

    $conn = \pg_connect($uniqueConnString);

    if ($conn === false) {
      $safeConnString = \preg_replace('/password=\S+/', 'password=***', $uniqueConnString) as string;
      throw new \Exception(
        'Failed to connect to PostgreSQL database. '.
        'Connection string: '.$safeConnString.'. '.
        'Check that the database server is running and accessible.'
      );
    }

    return $conn;
  }

  private function fetchAll(resource $result): vec<dict<string, mixed>> {
    $rows = vec[];
    while (true) {
      $row = \pg_fetch_assoc($result);
      if (!$row) {
        break;
      }
      $rows[] = dict($row);
    }
    return $rows;
  }
}
