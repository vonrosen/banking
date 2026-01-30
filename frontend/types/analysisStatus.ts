export enum AnalysisStatus {
  PENDING = 'pending',
  DOWNLOADING_TRANSACTIONS = 'downloading_transactions',
  ANALYZING_TRANSACTIONS = 'analyzing_transactions',
  AWAITING_PROVIDER_CONSENT = 'awaiting_provider_consent',
  SCRAPING_PROVIDER = 'scraping_provider',
  FETCHING_QUOTES = 'fetching_quotes',
  COMPLETED = 'completed',
  FAILED = 'failed',
}

export const STATUS_DISPLAY_TEXT: Record<AnalysisStatus, string> = {
  [AnalysisStatus.PENDING]: 'Starting...',
  [AnalysisStatus.DOWNLOADING_TRANSACTIONS]: 'Downloading transactions...',
  [AnalysisStatus.ANALYZING_TRANSACTIONS]: 'Analyzing your transactions...',
  [AnalysisStatus.AWAITING_PROVIDER_CONSENT]: 'Waiting for provider consent...',
  [AnalysisStatus.SCRAPING_PROVIDER]: 'Gathering provider information...',
  [AnalysisStatus.FETCHING_QUOTES]: 'Fetching quotes...',
  [AnalysisStatus.COMPLETED]: 'Analysis complete!',
  [AnalysisStatus.FAILED]: 'Analysis failed',
};

export const STATUS_ORDER: AnalysisStatus[] = [
  AnalysisStatus.PENDING,
  AnalysisStatus.DOWNLOADING_TRANSACTIONS,
  AnalysisStatus.ANALYZING_TRANSACTIONS,
  AnalysisStatus.AWAITING_PROVIDER_CONSENT,
  AnalysisStatus.SCRAPING_PROVIDER,
  AnalysisStatus.FETCHING_QUOTES,
  AnalysisStatus.COMPLETED,
];

export function isTerminalStatus(status: AnalysisStatus): boolean {
  return status === AnalysisStatus.COMPLETED || status === AnalysisStatus.FAILED;
}

export function getStatusStep(status: AnalysisStatus): number {
  const index = STATUS_ORDER.indexOf(status);
  return index === -1 ? 0 : index + 1;
}

export function getTotalSteps(): number {
  return STATUS_ORDER.length;
}
