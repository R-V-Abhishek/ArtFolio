import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import '../models/art_piece.dart';
// import '../widgets/art_card.dart';
import 'feed_screen.dart';
import 'image_upload_test_screen.dart';
import '../services/auth_service.dart';
import '../services/session_state.dart';
import '../services/firestore_service.dart';
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
          PopupMenuButton<String>(
            tooltip: 'Test Options',
            icon: const Icon(Icons.science),
            onSelected: (value) async {
              switch (value) {
                case 'test_firestore':
                  final firestoreService = FirestoreService();
                  await firestoreService.testFetchPosts();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Firestore test completed! Check console for results.',
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                  break;
                case 'test_storage':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImageUploadTestScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'test_firestore',
                child: ListTile(
                  leading: Icon(Icons.cloud),
                  title: Text('Test Firestore'),
                  subtitle: Text('Fetch posts from database'),
                ),
              ),
              const PopupMenuItem(
                value: 'test_storage',
                child: ListTile(
                  leading: Icon(Icons.cloud_upload),
                  title: Text('Test Storage'),
                  subtitle: Text('Upload images to Firebase'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: const FeedScreen(),
    );
  }
}
