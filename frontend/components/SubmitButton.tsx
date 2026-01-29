import { useState } from 'react';
import { StyleSheet } from 'react-native';
import { ActivityIndicator, Button } from 'react-native-paper';

type SubmitButtonProps = {
  label: string;
  onPress: () => void | Promise<void>;
  disabled?: boolean;
};

export function SubmitButton({ label, onPress, disabled = false }: SubmitButtonProps) {
  const [isLoading, setIsLoading] = useState(false);

  const handlePress = async () => {
    setIsLoading(true);
    try {
      await onPress();
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Button
      mode="contained"
      onPress={handlePress}
      disabled={disabled || isLoading}
      contentStyle={styles.content}
      style={styles.button}
      icon={isLoading ? () => <ActivityIndicator size={18} color="#fff" /> : undefined}
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
