import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import '../models/art_piece.dart';
// import '../widgets/art_card.dart';
import 'feed_screen.dart';
import '../services/auth_service.dart';
import '../services/session_state.dart';
import '../theme/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = SessionState.instance.guestMode.value || user == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ArtFolio'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () => themeController.toggle(),
            icon: Icon(
              themeController.value == ThemeMode.dark
                  ? Icons.nightlight_round
                  : Icons.wb_sunny,
            ),
          ),
          IconButton(
            tooltip: isGuest ? 'Sign In' : 'Sign Out',
            icon: Icon(isGuest ? Icons.login : Icons.logout),
            onPressed: () async {
              if (isGuest) {
                SessionState.instance.exitGuest();
              } else {
                await AuthService.instance.signOut();
              }
            },
          ),
        ],
      ),
      body: const FeedScreen(),
    );
  }
}
