import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/theme.dart';
import 'services/auth_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/session_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) => ValueListenableBuilder<bool>(
        valueListenable: SessionState.instance.guestMode,
        builder: (context, isGuest, __) => MaterialApp(
          title: 'ArtFolio',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: mode,
            home: isGuest
                ? const HomeScreen()
                : StreamBuilder(
                    stream: AuthService.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasData) {
                        return const HomeScreen();
                      }
                      return const AuthScreen();
                    },
                  ),
        ),
      ),
    );
  }
}

// Legacy MyHomePage removed in favor of new feature-rich HomeScreen.
