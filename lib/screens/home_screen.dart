import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'feed_screen.dart';
import 'image_upload_test_screen.dart';
import 'create_post_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import '../services/session_state.dart';
import '../services/firestore_service.dart';
import '../theme/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = SessionState.instance.guestMode.value || user == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ArtFolio'),
        actions: [
          // Notifications button requested in top-right
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
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
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'test_firestore',
                child: ListTile(
                  leading: Icon(Icons.cloud),
                  title: Text('Test Firestore'),
                  subtitle: Text('Fetch posts from database'),
                ),
              ),
              PopupMenuItem(
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
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          FeedScreen(),
          SearchScreen(),
          SizedBox.shrink(), // Create handled via FAB/center action
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          if (i == 2) {
            // Create tab acts as central action: open create post
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CreatePostScreen(),
                fullscreenDialog: true,
              ),
            );
            return;
          }
          setState(() => _currentIndex = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
