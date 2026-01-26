import { SubmitButton } from '@/components/SubmitButton';
import { StyleSheet, View } from 'react-native';

export default function ConnectBankScreen() {
  const handleConnectBank = () => {
    // TODO: Implement bank connection
    console.log('Connect bank account pressed');
  };

  return (
    <View style={styles.container}>
      <SubmitButton label="Connect Bank Account" onPress={handleConnectBank} />
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
