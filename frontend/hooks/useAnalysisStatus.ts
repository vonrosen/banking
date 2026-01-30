import { get } from '@/services/api';
import { RootState, store } from '@/store';
import { setError, updateAnalysis } from '@/store/slices/analysisSlice';
import { Analysis } from '@/types/analysis';
import { isTerminalStatus } from '@/types/analysisStatus';
import { useEffect, useRef } from 'react';
import { useSelector } from 'react-redux';

const POLLING_INTERVAL_MS = 2000;

export function useAnalysisStatus(analysisId: string | null) {
  const { currentAnalysis, error } = useSelector(
    (state: RootState) => state.analysis
  );
  const pollingRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const currentStatus = currentAnalysis?.status ?? null;

  useEffect(() => {
    if (!analysisId) return;
    if (pollingRef.current) return;

    const fetchAnalysis = async () => {
      try {
        const analysis = await get<Analysis>(`/v1/analyses/${analysisId}`);
        store.dispatch(updateAnalysis(analysis));
        if (isTerminalStatus(analysis.status)) {
          if (pollingRef.current) {
            clearInterval(pollingRef.current);
            pollingRef.current = null;
          }
        }
      } catch (err) {
        store.dispatch(setError(err instanceof Error ? err.message : 'Failed to fetch analysis'));
        if (pollingRef.current) {
          clearInterval(pollingRef.current);
          pollingRef.current = null;
        }
      }
    };

    fetchAnalysis();
    pollingRef.current = setInterval(fetchAnalysis, POLLING_INTERVAL_MS);

    return () => {
      if (pollingRef.current) {
        clearInterval(pollingRef.current);
        pollingRef.current = null;
      }
    };
  }, [analysisId]);

  return {
    currentAnalysis,
    currentStatus,
    error,
  };
}
