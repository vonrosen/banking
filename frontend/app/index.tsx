import { StyleSheet, View } from 'react-native';
import { Button } from 'react-native-paper';
import { router } from 'expo-router';

export default function WelcomeScreen() {
  return (
    <View style={styles.container}>
      <View style={styles.buttonContainer}>
        <Button
          mode="contained"
          onPress={() => router.push('/signup')}
          contentStyle={styles.signUpContent}
          labelStyle={styles.signUpLabel}
          style={styles.signUpButton}
        >
          Sign Up
        </Button>
        <Button
          mode="outlined"
          onPress={() => {}}
          style={styles.loginButton}
        >
          Login
        </Button>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  buttonContainer: {
    width: '100%',
    gap: 16,
  },
  signUpButton: {
    borderRadius: 12,
  },
  signUpContent: {
    paddingVertical: 12,
  },
  signUpLabel: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  loginButton: {
    alignSelf: 'center',
  },
});
