namespace Banking\Worker;

use type Banking\Models\InsuranceAnalysisStatus;

interface Worker {
    public function getStepStatus(): InsuranceAnalysisStatus;
    public function run(): Awaitable<void>;
}