import { useColorScheme } from '@/hooks/use-color-scheme';
import { persistor, store } from '@/store';
import { DarkTheme as NavigationDarkTheme, DefaultTheme as NavigationDefaultTheme, ThemeProvider } from '@react-navigation/native';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import {
  MD3DarkTheme,
  MD3LightTheme,
  PaperProvider,
  adaptNavigationTheme,
} from 'react-native-paper';
import 'react-native-reanimated';
import { Provider } from 'react-redux';
import { PersistGate } from 'redux-persist/integration/react';

const { LightTheme, DarkTheme } = adaptNavigationTheme({
  reactNavigationLight: NavigationDefaultTheme,
  reactNavigationDark: NavigationDarkTheme,
});

const paperLightTheme = {
  ...MD3LightTheme,
  colors: {
    ...MD3LightTheme.colors,
    ...LightTheme.colors,
  },
};

const paperDarkTheme = {
  ...MD3DarkTheme,
  colors: {
    ...MD3DarkTheme.colors,
    ...DarkTheme.colors,
  },
};

export default function RootLayout() {
  const colorScheme = useColorScheme();
  const paperTheme = colorScheme === 'dark' ? paperDarkTheme : paperLightTheme;
  const navigationTheme = colorScheme === 'dark' ? DarkTheme : LightTheme;

  return (
    <Provider store={store}>
      <PersistGate loading={null} persistor={persistor}>
        <PaperProvider theme={paperTheme}>
          <ThemeProvider value={navigationTheme}>
            <Stack>
              <Stack.Screen name="index" options={{ headerShown: false, title: 'Welcome' }} />
              <Stack.Screen name="signup" options={{ title: 'Sign Up' }} />
              <Stack.Screen name="login" options={{ title: 'Login' }} />
              <Stack.Screen name="connect-bank" options={{ title: 'Connect Bank Account', headerBackVisible: false }} />
              <Stack.Screen name="analysis-result" options={{ title: 'Analysis Result', headerBackVisible: false }} />
              <Stack.Screen name="insurance-login" options={{ title: 'Insurance Login', headerBackVisible: false }} />
            </Stack>
            <StatusBar style="auto" />
          </ThemeProvider>
        </PaperProvider>
      </PersistGate>
    </Provider>
  );
}
