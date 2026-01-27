namespace Banking\Repositories;

use type Banking\Models\{Analysis, CreateAnalysis};

interface IAnalysisRepository {
  public function createAnalysis(CreateAnalysis $request): Awaitable<Analysis>;
}
