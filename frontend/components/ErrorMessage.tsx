import { StyleSheet } from 'react-native';
import { Text } from 'react-native-paper';

type ErrorMessageProps = {
  message: string;
  visible: boolean;
};

export function ErrorMessage({ message, visible }: ErrorMessageProps) {
  return (
    <Text style={[styles.error, !visible && styles.hidden]}>
      {message}
    </Text>
  );
}

const styles = StyleSheet.create({
  error: {
    color: '#B00020',
    fontSize: 14,
    textAlign: 'center',
  },
  hidden: {
    opacity: 0,
  },
});
