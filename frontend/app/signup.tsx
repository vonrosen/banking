import { useState, useRef, useEffect } from 'react';
import { StyleSheet, View, KeyboardAvoidingView, Platform, TextInput as RNTextInput } from 'react-native';
import { Button, TextInput, HelperText } from 'react-native-paper';

function isValidUSPhoneNumber(phone: string): boolean {
  // Remove all non-digit characters
  const digits = phone.replace(/\D/g, '');
  // US phone numbers should have 10 digits (or 11 if starting with 1)
  if (digits.length === 10) {
    return true;
  }
  if (digits.length === 11 && digits.startsWith('1')) {
    return true;
  }
  return false;
}

function formatPhoneNumber(value: string): string {
  const digits = value.replace(/\D/g, '');
  if (digits.length <= 3) {
    return digits;
  }
  if (digits.length <= 6) {
    return `(${digits.slice(0, 3)}) ${digits.slice(3)}`;
  }
  return `(${digits.slice(0, 3)}) ${digits.slice(3, 6)}-${digits.slice(6, 10)}`;
}

export default function SignUpScreen() {
  const phoneInputRef = useRef<RNTextInput>(null);
  const [phoneNumber, setPhoneNumber] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [phoneError, setPhoneError] = useState('');
  const [passwordError, setPasswordError] = useState('');

  useEffect(() => {
    phoneInputRef.current?.focus();
  }, []);

  const handlePhoneChange = (value: string) => {
    const formatted = formatPhoneNumber(value);
    setPhoneNumber(formatted);
    if (phoneError) {
      setPhoneError('');
    }
  };

  const handleSubmit = () => {
    let hasError = false;

    if (!isValidUSPhoneNumber(phoneNumber)) {
      setPhoneError('Please enter a valid US phone number');
      hasError = true;
    }

    if (password.length < 8) {
      setPasswordError('Password must be at least 8 characters');
      hasError = true;
    } else {
      setPasswordError('');
    }

    if (!hasError) {
      // TODO: Handle signup logic
      console.log('Signup submitted', { phoneNumber, password });
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <View style={styles.form}>
        <View>
          <TextInput
            ref={phoneInputRef}
            label="Phone Number"
            value={phoneNumber}
            onChangeText={handlePhoneChange}
            keyboardType="phone-pad"
            mode="outlined"
            placeholder="(555) 555-5555"
            error={!!phoneError}
            left={<TextInput.Affix text="+1" />}
          />
          <HelperText type="error" visible={!!phoneError}>
            {phoneError}
          </HelperText>
        </View>

        <View>
          <TextInput
            label="Password"
            value={password}
            onChangeText={(value) => {
              setPassword(value);
              if (passwordError) setPasswordError('');
            }}
            secureTextEntry={!showPassword}
            mode="outlined"
            error={!!passwordError}
            right={
              <TextInput.Icon
                icon={showPassword ? 'eye-off' : 'eye'}
                onPress={() => setShowPassword(!showPassword)}
              />
            }
          />
          <HelperText type="error" visible={!!passwordError}>
            {passwordError}
          </HelperText>
        </View>

        <Button
          mode="contained"
          onPress={handleSubmit}
          contentStyle={styles.submitContent}
          style={styles.submitButton}
        >
          Submit
        </Button>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 24,
  },
  form: {
    gap: 8,
  },
  submitButton: {
    marginTop: 16,
    borderRadius: 8,
  },
  submitContent: {
    paddingVertical: 8,
  },
});
