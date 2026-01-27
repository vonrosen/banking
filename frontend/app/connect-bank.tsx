import { ErrorMessage } from '@/components/ErrorMessage';
import { SubmitButton } from '@/components/SubmitButton';
import { AnalysisService } from '@/services/analysisService';
import { RootState } from '@/store';
import { generateRandomToken } from '@/utils/random';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { useSelector } from 'react-redux';

export default function ConnectBankScreen() {
  const user = useSelector((state: RootState) => state.user.user);
  const [isLoading, setIsLoading] = useState(false);
  const [showError, setShowError] = useState(false);

  const handleConnectBank = async () => {
    if (!user) {
      setShowError(true);
      return;
    }

    setShowError(false);
    setIsLoading(true);

    try {
      const analysisService = new AnalysisService();
      const analysis = await analysisService.createAnalysis({
        user_id: user.id,
        bank_login_token: generateRandomToken(),
      });
      console.log('Analysis created:', analysis);
    } catch (error) {
      console.error('Failed to create analysis:', error);
      setShowError(true);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.errorContainer}>
        <ErrorMessage message="Failed to connect bank account" visible={showError} />
      </View>
      <SubmitButton
        label="Connect Bank Account"
        onPress={handleConnectBank}
        loading={isLoading}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 24,
  },
  errorContainer: {
    position: 'absolute',
    top: 60,
    left: 24,
    right: 24,
  },
});
