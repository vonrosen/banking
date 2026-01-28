namespace Banking\Worker;

use type Banking\Models\InsuranceAnalysisStatus;

interface Worker {
    public function getCompletionStatus(): InsuranceAnalysisStatus;
    public function run(): Awaitable<void>;
}