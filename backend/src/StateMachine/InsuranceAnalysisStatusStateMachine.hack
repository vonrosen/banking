namespace Banking\StateMachine;

use type Banking\Models\InsuranceAnalysisStatus;

type StatusTransition = shape(
  'status' => InsuranceAnalysisStatus,
  'stream' => ?string,
);

final class InsuranceAnalysisStatusStateMachine {

  private function getStreamName(InsuranceAnalysisStatus $status): ?string {
    switch ($status) {
      case InsuranceAnalysisStatus::DOWNLOADING_TRANSACTIONS:
        return 'insurance:get_bank_transactions';
      case InsuranceAnalysisStatus::ANALYZING_TRANSACTIONS:
        return 'insurance:analyze_bank_transactions';
      case InsuranceAnalysisStatus::SCRAPING_PROVIDER:
        return 'insurance:scrape_provider';
      case InsuranceAnalysisStatus::FETCHING_QUOTES:
        return 'insurance:fetch_quotes';
      case InsuranceAnalysisStatus::COMPLETED:
        return 'insurance:completion';
      case InsuranceAnalysisStatus::PENDING:
      case InsuranceAnalysisStatus::AWAITING_PROVIDER_CONSENT:
      case InsuranceAnalysisStatus::FAILED:
        return null;
    }
  }

  public function getInitialStatus(): StatusTransition {
    $status = InsuranceAnalysisStatus::PENDING;
    return shape(
      'status' => $status,
      'stream' => $this->getStreamName($status),
    );
  }

  public function getNextStatus(
    InsuranceAnalysisStatus $current,
  ): ?StatusTransition {
    $nextStatus = $this->getNextStatusEnum($current);
    if ($nextStatus is null) {
      return null;
    }
    return shape(
      'status' => $nextStatus,
      'stream' => $this->getStreamName($nextStatus),
    );
  }

  private function getNextStatusEnum(
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

  public function canTransition(
    InsuranceAnalysisStatus $from,
    InsuranceAnalysisStatus $to,
  ): bool {
    if ($to === InsuranceAnalysisStatus::FAILED) {
      return true;
    }

    $nextStatus = $this->getNextStatusEnum($from);
    return $nextStatus === $to;
  }

  public function isTerminal(InsuranceAnalysisStatus $status): bool {
    return $status === InsuranceAnalysisStatus::COMPLETED ||
           $status === InsuranceAnalysisStatus::FAILED;
  }

  public function requiresUserAction(InsuranceAnalysisStatus $status): bool {
    return $status === InsuranceAnalysisStatus::AWAITING_PROVIDER_CONSENT;
  }

  public function getProgressPercent(InsuranceAnalysisStatus $status): int {
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
