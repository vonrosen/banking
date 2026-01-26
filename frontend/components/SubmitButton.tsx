import { StyleSheet } from 'react-native';
import { ActivityIndicator, Button } from 'react-native-paper';

type SubmitButtonProps = {
  label: string;
  onPress: () => void | Promise<void>;
  disabled?: boolean;
  loading?: boolean;
};

export function SubmitButton({ label, onPress, disabled = false, loading = false }: SubmitButtonProps) {
  return (
    <Button
      mode="contained"
      onPress={onPress}
      disabled={disabled || loading}
      contentStyle={styles.content}
      style={styles.button}
      icon={loading ? () => <ActivityIndicator size={18} color="#fff" /> : undefined}
    >
      {label}
    </Button>
  );
}

const styles = StyleSheet.create({
  button: {
    marginTop: 16,
    borderRadius: 8,
  },
  content: {
    paddingVertical: 8,
  },
});
