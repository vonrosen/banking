namespace Banking\Repositories;

use type Banking\Models\{Analysis, CreateAnalysis};

interface IAnalysisRepository {
  public function createAnalysis(CreateAnalysis $request): Awaitable<Analysis>;

  public function getAnalysis(string $analysis_id): Awaitable<?Analysis>;

  public function updateAnalysisTransactionData(
    string $analysis_id,
    string $transaction_data,
  ): Awaitable<void>;

  public function updateAnalysisLLMResult(
    string $analysis_id,
    string $llm_result,
  ): Awaitable<void>;

  public function updateAnalysisStatus(
    string $analysis_id,
    string $status,
  ): Awaitable<Analysis>;
}
