import { StyleSheet, Text, View } from 'react-native';

export function AnalysisResult() {
  return (
    <View style={styles.container}>
      <Text style={styles.successIcon}>✓</Text>
      <Text style={styles.title}>Complete</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    padding: 24,
  },
  successIcon: {
    fontSize: 48,
    color: '#34C759',
    marginBottom: 16,
  },
  title: {
    fontSize: 24,
    fontWeight: '600',
    color: '#333',
  },
});
