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
      tuple('002_create_insurance_analysis_table', async () ==> await $this->migration002CreateInsuranceAnalysisTableAsync()),
      tuple('003_create_insurance_policy_table', async () ==> await $this->migration003CreateInsurancePolicyTableAsync()),
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

  private async function migration002CreateInsuranceAnalysisTableAsync(): Awaitable<void> {
    $sql = <<<SQL
CREATE TABLE IF NOT EXISTS insurance_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES "user"(id),
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  consent_token TEXT NOT NULL,
  transaction_data JSONB,
  llm_analysis_result JSONB,
  provider_policy_details JSONB,
  mcp_quotes JSONB,
  error_message TEXT,
  error_step VARCHAR(50),
  retry_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
SQL;
    await $this->connectionManager->queryAsync($sql);

    await $this->connectionManager->queryAsync(
      'CREATE INDEX IF NOT EXISTS idx_insurance_analysis_user_id ON insurance_analysis(user_id)',
    );

    await $this->connectionManager->queryAsync(
      'CREATE INDEX IF NOT EXISTS idx_insurance_analysis_status ON insurance_analysis(status)',
    );
  }

  private async function migration003CreateInsurancePolicyTableAsync(): Awaitable<void> {
    $sql = <<<SQL
CREATE TABLE IF NOT EXISTS insurance_policy (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES "user"(id),
  provider_name VARCHAR(100) NOT NULL,
  monthly_cost DECIMAL(10, 2) NOT NULL,
  quote_details JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
SQL;
    await $this->connectionManager->queryAsync($sql);

    await $this->connectionManager->queryAsync(
      'CREATE INDEX IF NOT EXISTS idx_insurance_policy_user_id ON insurance_policy(user_id)',
    );
  }
}
