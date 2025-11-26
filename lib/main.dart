import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'firebase_options.dart';
import 'routes/route_generator.dart';
import 'services/session_state.dart';
import 'theme/responsive.dart';
import 'theme/theme.dart';

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
    Firebase.app();
  }

  // Ensure Firebase App Check is activated to prevent placeholder token warnings
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
    );
  } catch (_) {
    // In older emulators or missing Play Services, activation may fail; continue gracefully
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: themeController,
    builder: (context, mode, _) => ValueListenableBuilder<bool>(
      valueListenable: SessionState.instance.guestMode,
      builder: (context, isGuest, _) => ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) => MaterialApp(
          title: 'ArtFolio',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode,

          builder: (context, innerChild) =>
              ResponsiveScaffold(child: innerChild ?? const SizedBox.shrink()),

          // Use route generator for named navigation
          onGenerateRoute: RouteGenerator.generateRoute,
          initialRoute: '/',
        ),
      ),
    ),
  );
}
