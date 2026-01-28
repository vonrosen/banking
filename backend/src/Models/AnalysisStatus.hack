namespace Banking\Models;

enum AnalysisStatus: string {
  PENDING = 'pending';
  DOWNLOADING_TRANSACTIONS = 'downloading_transactions';
  ANALYZING_TRANSACTIONS = 'analyzing_transactions';
  AWAITING_PROVIDER_CONSENT = 'awaiting_provider_consent';
  SCRAPING_PROVIDER = 'scraping_provider';
  FETCHING_QUOTES = 'fetching_quotes';
  COMPLETED = 'completed';
  FAILED = 'failed';
}
