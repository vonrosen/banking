namespace Banking\StateMachine;

use type Banking\Models\InsuranceAnalysisStatus;

final class InsuranceAnalysisStatusStateMachine {

  public static function getNextStatus(
    InsuranceAnalysisStatus $current,
  ): ?InsuranceAnalysisStatus {
    switch ($current) {
      case InsuranceAnalysisStatus::PENDING:
        return InsuranceAnalysisStatus::DOWNLOADING_TRANSACTIONS;
      case InsuranceAnalysisStatus::DOWNLOADING_TRANSACTIONS:
        return InsuranceAnalysisStatus::ANALYZING_TRANSACTIONS;
      case InsuranceAnalysisStatus::ANALYZING_TRANSACTIONS:
        return InsuranceAnalysisStatus::AWAITING_PROVIDER_CONSENT;
      case InsuranceAnalysisStatus::AWAITING_PROVIDER_CONSENT:
        return InsuranceAnalysisStatus::SCRAPING_PROVIDER;
      case InsuranceAnalysisStatus::SCRAPING_PROVIDER:
        return InsuranceAnalysisStatus::FETCHING_QUOTES;
      case InsuranceAnalysisStatus::FETCHING_QUOTES:
        return InsuranceAnalysisStatus::COMPLETED;
      case InsuranceAnalysisStatus::COMPLETED:
      case InsuranceAnalysisStatus::FAILED:
        return null;
    }
  }

  public static function canTransition(
    InsuranceAnalysisStatus $from,
    InsuranceAnalysisStatus $to,
  ): bool {
    if ($to === InsuranceAnalysisStatus::FAILED) {
      return true;
    }

    $nextStatus = self::getNextStatus($from);
    return $nextStatus === $to;
  }

  public static function isTerminal(InsuranceAnalysisStatus $status): bool {
    return $status === InsuranceAnalysisStatus::COMPLETED ||
           $status === InsuranceAnalysisStatus::FAILED;
  }

  public static function requiresUserAction(InsuranceAnalysisStatus $status): bool {
    return $status === InsuranceAnalysisStatus::AWAITING_PROVIDER_CONSENT;
  }

  public static function getProgressPercent(InsuranceAnalysisStatus $status): int {
    switch ($status) {
      case InsuranceAnalysisStatus::PENDING:
        return 0;
      case InsuranceAnalysisStatus::DOWNLOADING_TRANSACTIONS:
        return 20;
      case InsuranceAnalysisStatus::ANALYZING_TRANSACTIONS:
        return 40;
      case InsuranceAnalysisStatus::AWAITING_PROVIDER_CONSENT:
        return 50;
      case InsuranceAnalysisStatus::SCRAPING_PROVIDER:
        return 60;
      case InsuranceAnalysisStatus::FETCHING_QUOTES:
        return 80;
      case InsuranceAnalysisStatus::COMPLETED:
        return 100;
      case InsuranceAnalysisStatus::FAILED:
        return -1;
    }
  }
}
