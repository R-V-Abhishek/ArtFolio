import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/theme.dart';
import 'services/auth_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/session_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Attach to auto-initialized default app when present (Android/iOS via Google Services),
  // otherwise initialize with our options. Add a short wait to avoid race conditions
  // where native auto-init completes between the check and explicit initialization.
  if (Firebase.apps.isEmpty) {
    // Wait up to ~1s for native auto-init (10 x 100ms)
    for (var i = 0; i < 10 && Firebase.apps.isEmpty; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      // Ignore duplicate-app if native auto-init completed between check and call
      if (e.code != 'duplicate-app') rethrow;
    } catch (_) {}
  } else {
    // Ensure the default app is accessible; no-op if already set up
    Firebase.app();
  }
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
        builder: (context, isGuest, _) => MaterialApp(
          title: 'ArtFolio',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode,
          home: SplashScreen(
            next: isGuest
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
      ),
    );
  }
}
