namespace Banking\Logging;

use namespace HH\Lib\C;
use type HackLogging\Logger;

final class LoggerFactory {

  private static dict<string, Logger> $loggers = dict[];

  public static function getLogger(string $name): Logger {
    if (!C\contains_key(self::$loggers, $name)) {
      // Use file-based handler to avoid polluting HTTP responses
      self::$loggers[$name] = new Logger($name, vec[new FileLogHandler('/tmp/app.log')]);
    }
    return self::$loggers[$name];
  }
}
