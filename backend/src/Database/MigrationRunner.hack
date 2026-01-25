namespace Banking\Database;

use namespace HH\Lib\Str;
use namespace HH\Lib\C;

final class MigrationRunner {

  private static async function ensureMigrationsTableAsync(): Awaitable<void> {
    $sql = <<<SQL
CREATE TABLE IF NOT EXISTS schema_migration (
  version VARCHAR(255) PRIMARY KEY,
  applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
SQL;
    await ConnectionManager::queryAsync($sql);
  }

  private static async function isMigrationAppliedAsync(string $version): Awaitable<bool> {
    $rows = await ConnectionManager::queryAsync(
      'SELECT 1 FROM schema_migration WHERE version = $1',
      vec[$version],
    );
    return C\count($rows) > 0;
  }

  private static async function markMigrationAppliedAsync(string $version): Awaitable<void> {
    await ConnectionManager::queryAsync(
      'INSERT INTO schema_migration (version) VALUES ($1)',
      vec[$version],
    );
  }

  /**
   * Run all pending migrations.
   */
  public static async function runMigrationsAsync(): Awaitable<void> {
    \error_log('[MigrationRunner] Starting migrations...');

    try {
      \error_log('[MigrationRunner] Ensuring migrations table exists...');
      await self::ensureMigrationsTableAsync();
      \error_log('[MigrationRunner] Migrations table ready.');
    } catch (\Exception $e) {
      \error_log('[MigrationRunner] Failed to create migrations table: '.$e->getMessage());
      throw $e;
    }

    $migrations = vec[
      tuple('001_create_user_table', async () ==> await self::migration001CreateUsersTableAsync()),
    ];

    foreach ($migrations as $migration) {
      list($version, $runner) = $migration;

      \error_log(Str\format('[MigrationRunner] Checking migration: %s', $version));

      if (await self::isMigrationAppliedAsync($version)) {
        \error_log(Str\format('[MigrationRunner] Migration already applied: %s', $version));
        continue;
      }

      \error_log(Str\format('[MigrationRunner] Running migration: %s', $version));
      try {
        await $runner();
        await self::markMigrationAppliedAsync($version);
        \error_log(Str\format('[MigrationRunner] Migration completed: %s', $version));
      } catch (\Exception $e) {
        \error_log(Str\format('[MigrationRunner] Migration failed: %s - %s', $version, $e->getMessage()));
        throw $e;
      }
    }

    \error_log('[MigrationRunner] All migrations complete.');
  }

  private static async function migration001CreateUsersTableAsync(): Awaitable<void> {
    $sql = <<<SQL
CREATE TABLE IF NOT EXISTS "user" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number VARCHAR(20) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
SQL;
    await ConnectionManager::queryAsync($sql);

    await ConnectionManager::queryAsync(
      'CREATE INDEX IF NOT EXISTS idx_user_phone_number ON "user"(phone_number)',
    );
  }
}
