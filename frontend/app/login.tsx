import { ErrorMessage } from '@/components/ErrorMessage';
import { SubmitButton } from '@/components/SubmitButton';
import { UserService } from '@/services/userService';
import { AppDispatch } from '@/store';
import { setUser } from '@/store/slices/userSlice';
import { formatPhoneNumber, isValidUSPhoneNumber } from '@/utils/phoneNumber';
import { useRouter } from 'expo-router';
import { useEffect, useRef, useState } from 'react';
import { KeyboardAvoidingView, Platform, TextInput as RNTextInput, StyleSheet, View } from 'react-native';
import { HelperText, TextInput } from 'react-native-paper';
import { useDispatch } from 'react-redux';

export default function LoginScreen() {
  const dispatch = useDispatch<AppDispatch>();
  const router = useRouter();
  const phoneInputRef = useRef<RNTextInput>(null);
  const [phoneNumber, setPhoneNumber] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [phoneError, setPhoneError] = useState('');
  const [passwordError, setPasswordError] = useState('');
  const [showError, setShowError] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

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

  const isFormValid = isValidUSPhoneNumber(phoneNumber) && password.length >= 6;

  const handleSubmit = async () => {
    if (!isFormValid) return;

    const userService = new UserService();
    const digits = phoneNumber.replace(/\D/g, '');
    const formattedPhone = digits.length === 11 ? `+${digits}` : `+1${digits}`;

    setShowError(false);
    setIsLoading(true);
    try {
      const user = await userService.login({
        phone_number: formattedPhone,
        password,
      });
      dispatch(setUser(user));
      router.replace('/connect-bank');
    } catch (error) {
      console.error('Login failed', error);
      setShowError(true);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <View style={styles.errorContainer}>
        <ErrorMessage message="Login Failed" visible={showError} />
      </View>
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

        <SubmitButton
          label="Login"
          onPress={handleSubmit}
          disabled={!isFormValid}
          loading={isLoading}
        />
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
  errorContainer: {
    position: 'absolute',
    top: 60,
    left: 24,
    right: 24,
  },
  form: {
    gap: 8,
  },
});
