import { ErrorMessage } from '@/components/ErrorMessage';
import { SubmitButton } from '@/components/SubmitButton';
import { AnalysisService } from '@/services/analysisService';
import { AppDispatch, RootState } from '@/store';
import { setAnalysis } from '@/store/slices/analysisSlice';
import { generateRandomToken } from '@/utils/random';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { useDispatch, useSelector } from 'react-redux';

export default function ConnectBankScreen() {
  const router = useRouter();
  const dispatch = useDispatch<AppDispatch>();
  const user = useSelector((state: RootState) => state.user.user);
  const [showError, setShowError] = useState(false);

  const handleConnectBank = async () => {
    if (!user) {
      setShowError(true);
      return;
    }
    setShowError(false);
    try {
      const analysisService = new AnalysisService();
      const analysis = await analysisService.createAnalysis({
        user_id: user.id,
        bank_login_token: generateRandomToken(),
      });
      dispatch(setAnalysis(analysis));
      console.log('Analysis created with ID:', analysis.id);
      router.push('/analysis-result');
    } catch (error) {
      console.error('Failed to create analysis:', error);
      setShowError(true);
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
