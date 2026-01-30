import { useAnalysisStatus } from '@/hooks/useAnalysisStatus';
import {
  AnalysisStatus,
  STATUS_DISPLAY_TEXT,
  getStatusStep,
  getTotalSteps,
  isTerminalStatus,
} from '@/types/analysisStatus';
import { useEffect, useState } from 'react';
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from 'react-native';
import { InsuranceLoginModal } from './InsuranceLoginModal';

type AnalysisProgressProps = {
  analysisId: string;
};

export function AnalysisProgress({ analysisId }: AnalysisProgressProps) {
  const { currentStatus, error } = useAnalysisStatus(analysisId);
  const [isModalVisible, setIsModalVisible] = useState(false);

  const status = currentStatus || AnalysisStatus.PENDING;
  const isAwaitingConsent = status === AnalysisStatus.AWAITING_PROVIDER_CONSENT;
  const displayText = STATUS_DISPLAY_TEXT[status];
  const currentStep = getStatusStep(status);
  const totalSteps = getTotalSteps();
  const progress = currentStep / totalSteps;
  const isTerminal = isTerminalStatus(status);

  // Auto-show modal when status becomes awaiting_provider_consent
  useEffect(() => {
    if (isAwaitingConsent) {
      setIsModalVisible(true);
    }
  }, [isAwaitingConsent]);

  const handleLoginSubmit = (username: string, password: string) => {
    // TODO: Submit credentials to backend
    console.log('Submitting credentials:', { username, password });
    setIsModalVisible(false);
  };

  const handleModalCancel = () => {
    setIsModalVisible(false);
  };

  const handleOpenModal = () => {
    setIsModalVisible(true);
  };

  return (
    <View style={styles.container}>
      <InsuranceLoginModal
        visible={isModalVisible}
        onSubmit={handleLoginSubmit}
        onCancel={handleModalCancel}
      />

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

      {isAwaitingConsent && !isModalVisible && (
        <Pressable style={styles.loginButton} onPress={handleOpenModal}>
          <Text style={styles.loginButtonText}>Enter Insurance Credentials</Text>
        </Pressable>
      )}

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
  loginButton: {
    marginTop: 24,
    paddingVertical: 10,
    paddingHorizontal: 16,
    backgroundColor: '#007AFF',
    borderRadius: 8,
  },
  loginButtonText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '500',
  },
  errorText: {
    fontSize: 14,
    color: '#FF3B30',
    marginTop: 16,
    textAlign: 'center',
  },
});
