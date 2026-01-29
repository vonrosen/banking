namespace Banking\StateMachine;

use namespace HH\Lib\Str;
use type Banking\Models\AnalysisStatus;

final class AnalysisStatusStateMachine {

  public function getInitialStatus(): AnalysisStatus {
    return AnalysisStatus::PENDING;
  }

  public function getNextStatus(
    AnalysisStatus $current,
  ): ?AnalysisStatus {
    switch ($current) {
      case AnalysisStatus::PENDING:
        return AnalysisStatus::DOWNLOADING_TRANSACTIONS;
      case AnalysisStatus::DOWNLOADING_TRANSACTIONS:
        return AnalysisStatus::ANALYZING_TRANSACTIONS;
      case AnalysisStatus::ANALYZING_TRANSACTIONS:
        return AnalysisStatus::AWAITING_PROVIDER_CONSENT;
      case AnalysisStatus::AWAITING_PROVIDER_CONSENT:
        return AnalysisStatus::SCRAPING_PROVIDER;
      case AnalysisStatus::SCRAPING_PROVIDER:
        return AnalysisStatus::FETCHING_QUOTES;
      case AnalysisStatus::FETCHING_QUOTES:
        return AnalysisStatus::COMPLETED;
      case AnalysisStatus::COMPLETED:
      case AnalysisStatus::FAILED:
        return null;
    }
  }
}
