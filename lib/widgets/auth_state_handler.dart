import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/user_type_selection_screen.dart';

class AuthStateHandler extends StatefulWidget {
  const AuthStateHandler({super.key});

  @override
  State<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // User is authenticated, check if they have a profile
          return FutureBuilder<bool>(
            future: _hasCompleteProfile(snapshot.data!.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (profileSnapshot.data == true) {
                // User has complete profile, go to home
                return const HomeScreen();
              } else {
                // User needs to complete profile setup
                final user = snapshot.data!;
                return UserTypeSelectionScreen(
                  uid: user.uid,
                  email: user.email ?? '',
                  fullName: user.displayName ?? '',
                  profilePictureUrl: user.photoURL,
                );
              }
            },
          );
        }

        // User is not authenticated
        return const AuthScreen();
      },
    );
  }

  Future<bool> _hasCompleteProfile(String uid) async {
    try {
      final user = await FirestoreService().getUser(uid);
      return user != null;
    } catch (e) {
      return false;
    }
  }
}