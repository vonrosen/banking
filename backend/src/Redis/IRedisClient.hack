namespace Banking\Redis;

type StreamMessage = shape(
  'id' => string,
  'fields' => dict<string, string>,
);

type StreamEntry = shape(
  'stream' => string,
  'messages' => vec<StreamMessage>,
);

interface IRedisClient {
  public function get(string $key): ?string;

  public function set(string $key, string $value): void;

  public function xadd(
    string $stream,
    dict<string, string> $fields,
    ?string $id = null,
  ): string;

  public function xread(
    vec<string> $streams,
    vec<string> $ids,
    ?int $count = null,
    ?int $blockMs = null,
  ): vec<StreamEntry>;

  /**
   * Create a consumer group on a stream.
   * Returns true if created, false if already exists.
   */
  public function xgroupCreate(
    string $stream,
    string $group,
    string $startId = '0',
    bool $mkstream = false,
  ): bool;

  /**
   * Read messages from a stream using a consumer group.
   * Each message is delivered to only one consumer in the group.
   */
  public function xreadgroup(
    string $group,
    string $consumer,
    vec<string> $streams,
    ?int $count = null,
    ?int $blockMs = null,
  ): vec<StreamEntry>;

  /**
   * Acknowledge that messages have been processed.
   */
  public function xack(
    string $stream,
    string $group,
    vec<string> $ids,
  ): int;
}
