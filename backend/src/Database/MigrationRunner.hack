namespace Banking\Database;

use namespace HH\Lib\Str;

final class MigrationRunner {

  private static function ensureMigrationsTable(): void {
    $sql = <<<SQL
CREATE TABLE IF NOT EXISTS schema_migration (
  version VARCHAR(255) PRIMARY KEY,
  applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
SQL;
    ConnectionManager::query($sql);
  }

  private static function isMigrationApplied(string $version): bool {
    $result = ConnectionManager::query(
      'SELECT 1 FROM schema_migration WHERE version = $1',
      vec[$version],
    );
    return \pg_num_rows($result) > 0;
  }

  private static function markMigrationApplied(string $version): void {
    ConnectionManager::query(
      'INSERT INTO schema_migration (version) VALUES ($1)',
      vec[$version],
    );
  }

  /**
   * Run all pending migrations.
   */
  public static function runMigrations(): void {
    self::ensureMigrationsTable();

    $migrations = vec[
      tuple('001_create_users_table', () ==> self::migration001CreateUsersTable()),
    ];

    foreach ($migrations as $migration) {
      list($version, $runner) = $migration;

      if (self::isMigrationApplied($version)) {
        continue;
      }

      \error_log(Str\format('Running migration: %s', $version));
      $runner();
      self::markMigrationApplied($version);
      \error_log(Str\format('Migration completed: %s', $version));
    }
  }

  private static function migration001CreateUsersTable(): void {
    $sql = <<<SQL
CREATE TABLE IF NOT EXISTS user (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number VARCHAR(20) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
SQL;
    ConnectionManager::query($sql);

    ConnectionManager::query(
      'CREATE INDEX IF NOT EXISTS idx_users_phone_number ON users(phone_number)',
    );
  }
}
