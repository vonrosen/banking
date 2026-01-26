namespace Banking\Logging;

use namespace HH\Lib\{C, IO};
use type HackLogging\Logger;
use type HackLogging\Handler\StdHandler;

final class LoggerFactory {

  private static dict<string, Logger> $loggers = dict[];

  public static function getLogger(string $name): Logger {
    if (!C\contains_key(self::$loggers, $name)) {
      self::$loggers[$name] = new Logger($name, vec[new StdHandler(IO\request_output())]);
    }
    return self::$loggers[$name];
  }
}
