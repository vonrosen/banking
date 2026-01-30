namespace Banking\Services;

use type Banking\Models\AnalysisStatus;

final class RedisStreamService {

    public function getStreamName(AnalysisStatus $status): ?string {
        switch ($status) {
        case AnalysisStatus::DOWNLOADING_TRANSACTIONS:
        case AnalysisStatus::ANALYZING_TRANSACTIONS:
        case AnalysisStatus::SCRAPING_PROVIDER:
        case AnalysisStatus::FETCHING_QUOTES:
        case AnalysisStatus::COMPLETED:
            return 'insurance:'.$status;
        case AnalysisStatus::PENDING:
        case AnalysisStatus::AWAITING_PROVIDER_CONSENT:
        case AnalysisStatus::FAILED:
            return null;
        }
    }
}