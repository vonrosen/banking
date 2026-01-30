import { useAnalysisStatus } from '@/hooks/useAnalysisStatus';
import {
  AnalysisStatus,
  STATUS_DISPLAY_TEXT,
  getStatusStep,
  getTotalSteps,
  isTerminalStatus,
} from '@/types/analysisStatus';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';

type AnalysisProgressProps = {
  analysisId: string;
};

export function AnalysisProgress({ analysisId }: AnalysisProgressProps) {
  const { currentStatus, error } = useAnalysisStatus(analysisId);

  const status = currentStatus || AnalysisStatus.PENDING;
  const displayText = STATUS_DISPLAY_TEXT[status];
  const currentStep = getStatusStep(status);
  const totalSteps = getTotalSteps();
  const progress = currentStep / totalSteps;
  const isTerminal = isTerminalStatus(status);

  return (
    <View style={styles.container}>
      <View style={styles.spinnerContainer}>
        {!isTerminal && <ActivityIndicator size="large" color="#007AFF" />}
        {status === AnalysisStatus.COMPLETED && (
          <Text style={styles.successIcon}>✓</Text>
        )}
        {status === AnalysisStatus.FAILED && (
          <Text style={styles.errorIcon}>✕</Text>
        )}
      </View>

      <Text style={styles.statusText}>{displayText}</Text>

      <View style={styles.progressBarContainer}>
        <View style={[styles.progressBar, { width: `${progress * 100}%` }]} />
      </View>

      <Text style={styles.stepText}>
        Step {currentStep} of {totalSteps}
      </Text>

      {error && <Text style={styles.errorText}>{error}</Text>}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    padding: 24,
  },
  spinnerContainer: {
    height: 48,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  successIcon: {
    fontSize: 36,
    color: '#34C759',
    fontWeight: 'bold',
  },
  errorIcon: {
    fontSize: 36,
    color: '#FF3B30',
    fontWeight: 'bold',
  },
  statusText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 24,
    textAlign: 'center',
  },
  progressBarContainer: {
    width: '100%',
    height: 8,
    backgroundColor: '#E5E5EA',
    borderRadius: 4,
    overflow: 'hidden',
    marginBottom: 12,
  },
  progressBar: {
    height: '100%',
    backgroundColor: '#007AFF',
    borderRadius: 4,
  },
  stepText: {
    fontSize: 14,
    color: '#8E8E93',
  },
  errorText: {
    fontSize: 14,
    color: '#FF3B30',
    marginTop: 16,
    textAlign: 'center',
  },
});
