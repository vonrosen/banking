import { SubmitButton } from '@/components/SubmitButton';
import { RootState } from '@/store';
import { useState } from 'react';
import { Modal, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { useSelector } from 'react-redux';

type InsuranceLoginModalProps = {
  visible: boolean;
  onSubmit: (username: string, password: string) => void;
  onCancel: () => void;
};

export function InsuranceLoginModal({ visible, onSubmit, onCancel }: InsuranceLoginModalProps) {
  const currentAnalysis = useSelector((state: RootState) => state.analysis.currentAnalysis);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');

  const getProviderName = (): string => {
    try {
      const llmResult = currentAnalysis?.llm_analysis_result;
        const parsed = JSON.parse(llmResult);
        return parsed?.insurance_payments?.[0]?.provider ?? 'your insurance provider';
    } catch {
      return 'your insurance provider';
    }
  };

  const providerName = getProviderName();

  const handleSubmit = () => {
    onSubmit(username, password);
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
    >
      <View style={styles.overlay}>
        <View style={styles.modal}>
          <Text style={styles.title}>Insurance Login</Text>

          <Text style={styles.consentMessage}>
            By entering your credentials, you consent to us securely logging into {providerName} on your behalf to retrieve your policy information.
          </Text>

          <View style={styles.form}>
            <Text style={styles.label}>Username</Text>
            <TextInput
              style={styles.input}
              value={username}
              onChangeText={setUsername}
              placeholder="Enter your username"
              autoCapitalize="none"
              autoCorrect={false}
            />

            <Text style={styles.label}>Password</Text>
            <TextInput
              style={styles.input}
              value={password}
              onChangeText={setPassword}
              placeholder="Enter your password"
              secureTextEntry
            />

            <View style={styles.buttonContainer}>
              <SubmitButton label="Login" onPress={handleSubmit} />
              <Pressable style={styles.cancelButton} onPress={onCancel}>
                <Text style={styles.cancelButtonText}>Cancel</Text>
              </Pressable>
            </View>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  modal: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 24,
    width: '100%',
    maxWidth: 400,
  },
  title: {
    fontSize: 20,
    fontWeight: '600',
    color: '#333',
    textAlign: 'center',
    marginBottom: 12,
  },
  consentMessage: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
    marginBottom: 24,
    lineHeight: 20,
  },
  form: {
    width: '100%',
  },
  label: {
    fontSize: 14,
    fontWeight: '500',
    color: '#333',
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: '#E5E5EA',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    marginBottom: 16,
  },
  buttonContainer: {
    marginTop: 8,
  },
  cancelButton: {
    marginTop: 12,
    paddingVertical: 12,
    alignItems: 'center',
  },
  cancelButtonText: {
    color: '#007AFF',
    fontSize: 16,
  },
});
