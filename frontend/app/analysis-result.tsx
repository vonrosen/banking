import { AnalysisProgress } from '@/components/AnalysisProgress';
import { AnalysisResult } from '@/components/AnalysisResult';
import { SubmitButton } from '@/components/SubmitButton';
import { AppDispatch, RootState } from '@/store';
import { clearAnalysis } from '@/store/slices/analysisSlice';
import { AnalysisStatus, isTerminalStatus } from '@/types/analysisStatus';
import { useRouter } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { useDispatch, useSelector } from 'react-redux';

export default function AnalysisResultScreen() {
  const router = useRouter();
  const dispatch = useDispatch<AppDispatch>();
  const currentAnalysis = useSelector((state: RootState) => state.analysis.currentAnalysis);

  const isProcessing = currentAnalysis && !isTerminalStatus(currentAnalysis.status);
  const isComplete = currentAnalysis?.status === AnalysisStatus.COMPLETED;

  const handleCancel = () => {
    dispatch(clearAnalysis());
    router.replace('/connect-bank');
  };

  return (
    <View style={styles.container}>
      {isProcessing && currentAnalysis && (
        <AnalysisProgress analysisId={currentAnalysis.id} />
      )}
      {isComplete && <AnalysisResult />}
      <SubmitButton label="Cancel" onPress={handleCancel} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 24,
  },
});
