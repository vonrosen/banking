namespace Banking\Redis;

use namespace HH\Lib\{Str, Vec};

final class RedisClient implements IRedisClient {
  private ?resource $socket = null;

  public function __construct(private RedisConfig $config) {}

  private function connect(): resource {
    if ($this->socket !== null) {
      return $this->socket;
    }

    $errno = 0;
    $errstr = '';
    $socket = \fsockopen(
      $this->config->getHost(),
      $this->config->getPort(),
      inout $errno,
      inout $errstr,
      $this->config->getTimeoutSeconds(),
    );

    if ($socket === false) {
      throw new \Exception(Str\format('Redis connection failed: %s (%d)', $errstr, $errno));
    }

    $this->socket = $socket;

    $password = $this->config->getPassword();
    if ($password !== null) {
      $this->sendCommand(vec['AUTH', $password]);
    }

    $database = $this->config->getDatabase();
    if ($database !== 0) {
      $this->sendCommand(vec['SELECT', (string)$database]);
    }

    return $socket;
  }

  private function sendCommand(vec<string> $args): mixed {
    $socket = $this->connect();

    $cmd = '*'.\count($args)."\r\n";
    foreach ($args as $arg) {
      $cmd .= '$'.Str\length($arg)."\r\n".$arg."\r\n";
    }

    \fwrite($socket, $cmd);

    return $this->readResponse($socket);
  }

  private function readResponse(resource $socket): mixed {
    $line = \fgets($socket);
    if ($line === false) {
      throw new \Exception('Failed to read from Redis');
    }

    $line = Str\trim_right($line, "\r\n");
    $type = $line[0];
    $data = Str\slice($line, 1);

    switch ($type) {
      case '+':
        return $data;
      case '-':
        throw new \Exception('Redis error: '.$data);
      case ':':
        return (int)$data;
      case '$':
        $length = (int)$data;
        if ($length === -1) {
          return null;
        }
        $bulk = \fread($socket, $length + 2);
        if ($bulk === false) {
          throw new \Exception('Failed to read bulk string from Redis');
        }
        return Str\slice($bulk, 0, $length);
      case '*':
        $count = (int)$data;
        if ($count === -1) {
          return null;
        }
        $result = vec[];
        for ($i = 0; $i < $count; $i++) {
          $result[] = $this->readResponse($socket);
        }
        return $result;
      default:
        throw new \Exception('Unknown Redis response type: '.$type);
    }
  }

  public function get(string $key): ?string {
    $result = $this->sendCommand(vec['GET', $key]);
    return $result is string ? $result : null;
  }

  public function set(string $key, string $value): void {
    $this->sendCommand(vec['SET', $key, $value]);
  }

  public function xadd(
    string $stream,
    dict<string, string> $fields,
    ?string $id = null,
  ): string {
    $args = vec['XADD', $stream, $id ?? '*'];
    foreach ($fields as $key => $value) {
      $args[] = $key;
      $args[] = $value;
    }
    $result = $this->sendCommand($args);
    return (string)$result;
  }

  public function xread(
    vec<string> $streams,
    vec<string> $ids,
    ?int $count = null,
    ?int $blockMs = null,
  ): vec<StreamEntry> {
    $args = vec['XREAD'];

    if ($count !== null) {
      $args[] = 'COUNT';
      $args[] = (string)$count;
    }

    if ($blockMs !== null) {
      $args[] = 'BLOCK';
      $args[] = (string)$blockMs;
    }

    $args[] = 'STREAMS';
    foreach ($streams as $stream) {
      $args[] = $stream;
    }
    foreach ($ids as $id) {
      $args[] = $id;
    }

    $result = $this->sendCommand($args);
    return $this->parseStreamResult($result);
  }

  private function parseStreamResult(mixed $result): vec<StreamEntry> {
    if ($result === null) {
      return vec[];
    }

    $entries = vec[];
    $streams = $result as vec<_>;

    foreach ($streams as $streamData) {
      $streamArr = $streamData as vec<_>;
      $streamName = (string)$streamArr[0];
      $messages = $streamArr[1] as vec<_>;

      $parsedMessages = vec[];
      foreach ($messages as $message) {
        $msgArr = $message as vec<_>;
        $msgId = (string)$msgArr[0];
        $fieldsArr = $msgArr[1] as vec<_>;

        $fields = dict[];
        for ($i = 0; $i < \count($fieldsArr); $i += 2) {
          $key = (string)$fieldsArr[$i];
          $value = (string)$fieldsArr[$i + 1];
          $fields[$key] = $value;
        }

        $parsedMessages[] = shape(
          'id' => $msgId,
          'fields' => $fields,
        );
      }

      $entries[] = shape(
        'stream' => $streamName,
        'messages' => $parsedMessages,
      );
    }

    return $entries;
  }

  public function xgroupCreate(
    string $stream,
    string $group,
    string $startId = '0',
    bool $mkstream = false,
  ): bool {
    try {
      $args = vec['XGROUP', 'CREATE', $stream, $group, $startId];
      if ($mkstream) {
        $args[] = 'MKSTREAM';
      }
      $this->sendCommand($args);
      return true;
    } catch (\Exception $e) {
      // Group already exists
      if (Str\contains($e->getMessage(), 'BUSYGROUP')) {
        return false;
      }
      throw $e;
    }
  }

  public function xreadgroup(
    string $group,
    string $consumer,
    vec<string> $streams,
    ?int $count = null,
    ?int $blockMs = null,
  ): vec<StreamEntry> {
    $args = vec['XREADGROUP', 'GROUP', $group, $consumer];

    if ($count !== null) {
      $args[] = 'COUNT';
      $args[] = (string)$count;
    }

    if ($blockMs !== null) {
      $args[] = 'BLOCK';
      $args[] = (string)$blockMs;
    }

    $args[] = 'STREAMS';
    foreach ($streams as $stream) {
      $args[] = $stream;
    }
    // Use '>' to get only new messages not yet delivered to any consumer
    foreach ($streams as $_) {
      $args[] = '>';
    }

    $result = $this->sendCommand($args);
    return $this->parseStreamResult($result);
  }

  public function xack(
    string $stream,
    string $group,
    vec<string> $ids,
  ): int {
    $args = vec['XACK', $stream, $group];
    foreach ($ids as $id) {
      $args[] = $id;
    }
    $result = $this->sendCommand($args);
    return (int)$result;
  }

  public function close(): void {
    if ($this->socket !== null) {
      \fclose($this->socket);
      $this->socket = null;
    }
  }
}
