namespace Banking\Database;

use namespace HH\Lib\Str;
use namespace HH\Lib\C;
use type Banking\Logging\LoggerFactory;
use type HackLogging\LogLevel;

final class MigrationRunner {

  private static function getLogger(): \HackLogging\Logger {
    return LoggerFactory::getLogger('MigrationRunner');
  }

  public function __construct(private ConnectionManager $connectionManager) {
  }

  private async function ensureMigrationsTableAsync(): Awaitable<void> {
    $sql = <<<SQL
CREATE TABLE IF NOT EXISTS schema_migration (
  version VARCHAR(255) PRIMARY KEY,
  applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
SQL;
    await $this->connectionManager->queryAsync($sql);
  }

  private async function isMigrationAppliedAsync(string $version): Awaitable<bool> {
    $rows = await $this->connectionManager->queryAsync(
      'SELECT 1 FROM schema_migration WHERE version = $1',
      vec[$version],
    );
    return C\count($rows) > 0;
  }

  private async function markMigrationAppliedAsync(string $version): Awaitable<void> {
    await $this->connectionManager->queryAsync(
      'INSERT INTO schema_migration (version) VALUES ($1)',
      vec[$version],
    );
  }

  public async function runMigrationsAsync(): Awaitable<void> {
    $logger = self::getLogger();
    await $logger->writeAsync(LogLevel::INFO, 'Starting migrations...', dict[]);

    try {
      await $logger->writeAsync(LogLevel::INFO, 'Ensuring migrations table exists...', dict[]);
      await $this->ensureMigrationsTableAsync();
      await $logger->writeAsync(LogLevel::INFO, 'Migrations table ready.', dict[]);
    } catch (\Exception $e) {
      await $logger->writeAsync(LogLevel::ERROR, 'Failed to create migrations table: '.$e->getMessage(), dict[]);
      throw $e;
    }

    $migrations = vec[
      tuple('001_create_user_table', async () ==> await $this->migration001CreateUsersTableAsync()),
    ];

    foreach ($migrations as $migration) {
      list($version, $runner) = $migration;

      await $logger->writeAsync(LogLevel::INFO, Str\format('Checking migration: %s', $version), dict[]);

      if (await $this->isMigrationAppliedAsync($version)) {
        await $logger->writeAsync(LogLevel::INFO, Str\format('Migration already applied: %s', $version), dict[]);
        continue;
      }

      await $logger->writeAsync(LogLevel::INFO, Str\format('Running migration: %s', $version), dict[]);
      try {
        await $runner();
        await $this->markMigrationAppliedAsync($version);
        await $logger->writeAsync(LogLevel::INFO, Str\format('Migration completed: %s', $version), dict[]);
      } catch (\Exception $e) {
        await $logger->writeAsync(LogLevel::ERROR, Str\format('Migration failed: %s - %s', $version, $e->getMessage()), dict[]);
        throw $e;
      }
    }

    await $logger->writeAsync(LogLevel::INFO, 'All migrations complete.', dict[]);
  }

  private async function migration001CreateUsersTableAsync(): Awaitable<void> {
    $sql = <<<SQL
CREATE TABLE IF NOT EXISTS "user" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number VARCHAR(20) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
SQL;
    await $this->connectionManager->queryAsync($sql);

    await $this->connectionManager->queryAsync(
      'CREATE INDEX IF NOT EXISTS idx_user_phone_number ON "user"(phone_number)',
    );
  }
}
