namespace Banking\Repositories;

use type Banking\Models\{Analysis, CreateAnalysis};
use type Banking\Database\ConnectionManager;
use namespace HH\Lib\C;

final class AnalysisRepository implements IAnalysisRepository {

  public function __construct(
    private ConnectionManager $connectionManager
  ) {}

  public async function createAnalysis(CreateAnalysis $analysis): Awaitable<Analysis> {
    $sql = <<<SQL
INSERT INTO insurance_analysis (user_id, bank_login_token)
VALUES (\$1, \$2)
RETURNING id, user_id, status, bank_login_token, transaction_data, llm_analysis_result, provider_policy_details, quotes, error_message, error_step, retry_count, created_at, updated_at
SQL;

    $rows = await $this->connectionManager->queryAsync($sql, vec[
      $analysis['user_id'],
      $analysis['bank_login_token'],
    ]);

    if (C\is_empty($rows)) {
      throw new \Exception('Failed to create analysis');
    }

    $row = $rows[0];
    $error_message = $row['error_message'];
    $error_step = $row['error_step'];
    return shape(
      'id' => (string)$row['id'],
      'user_id' => (string)$row['user_id'],
      'status' => (string)$row['status'],
      'bank_login_token' => (string)$row['bank_login_token'],
      'transaction_data' => $row['transaction_data'],
      'llm_analysis_result' => $row['llm_analysis_result'],
      'provider_policy_details' => $row['provider_policy_details'],
      'quotes' => $row['quotes'],
      'error_message' => $error_message is string ? $error_message : null,
      'error_step' => $error_step is string ? $error_step : null,
      'retry_count' => (int)$row['retry_count'],
      'created_at' => (string)$row['created_at'],
      'updated_at' => (string)$row['updated_at'],
    );
  }



  public async function getAnalysis(string $analysis_id): Awaitable<?Analysis> {
    $sql = <<<SQL
SELECT id, user_id, status, bank_login_token, transaction_data, llm_analysis_result, provider_policy_details, quotes, error_message, error_step, retry_count, created_at, updated_at
FROM insurance_analysis
WHERE id = \$1
SQL;

    $rows = await $this->connectionManager->queryAsync($sql, vec[$analysis_id]);

    if (C\is_empty($rows)) {
      return null;
    }

    $row = $rows[0];
    $error_message = $row['error_message'];
    $error_step = $row['error_step'];
    return shape(
      'id' => (string)$row['id'],
      'user_id' => (string)$row['user_id'],
      'status' => (string)$row['status'],
      'bank_login_token' => (string)$row['bank_login_token'],
      'transaction_data' => $row['transaction_data'],
      'llm_analysis_result' => $row['llm_analysis_result'],
      'provider_policy_details' => $row['provider_policy_details'],
      'quotes' => $row['quotes'],
      'error_message' => $error_message is string ? $error_message : null,
      'error_step' => $error_step is string ? $error_step : null,
      'retry_count' => (int)$row['retry_count'],
      'created_at' => (string)$row['created_at'],
      'updated_at' => (string)$row['updated_at'],
    );
  }

  public async function updateAnalysisTransactionData(
    string $analysis_id,
    string $transaction_data
    ): Awaitable<void> {
    $sql = <<<SQL
UPDATE insurance_analysis
SET transaction_data = \$1
WHERE id = \$2
SQL;
    await $this->connectionManager->queryAsync($sql, vec[
      $transaction_data,
      $analysis_id,
    ]);
  }

  public async function updateAnalysisLLMResult(
    string $analysis_id,
    string $llm_result,
  ): Awaitable<void> {
    $sql = <<<SQL
UPDATE insurance_analysis
SET llm_analysis_result = \$1, updated_at = CURRENT_TIMESTAMP
WHERE id = \$2
SQL;
    await $this->connectionManager->queryAsync($sql, vec[
      $llm_result,
      $analysis_id,
    ]);
  } 

  public async function updateAnalysisStatus(
    string $analysis_id,
    string $status,
  ): Awaitable<void> {
    $sql = <<<SQL
UPDATE insurance_analysis
SET status = \$1, updated_at = CURRENT_TIMESTAMP
WHERE id = \$2
SQL;
    await $this->connectionManager->queryAsync($sql, vec[
      $status,
      $analysis_id,
    ]); 
  }
}