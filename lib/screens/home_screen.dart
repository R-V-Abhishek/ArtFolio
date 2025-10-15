import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'feed_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import '../services/session_state.dart';
import '../services/firestore_service.dart';
import '../theme/theme.dart';
import '../theme/scale.dart';
import '../routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final s = Scale(context);
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = SessionState.instance.guestMode.value || user == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ArtFolio'),
        actions: [
          // Notifications button requested in top-right
          Builder(
            builder: (context) {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) {
                return IconButton(
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.notifications);
                  },
                  icon: const Icon(Icons.notifications_outlined),
                );
              }
              final service = FirestoreService();
              return StreamBuilder<int>(
                stream: service.unreadNotificationsCountStream(uid),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        tooltip: 'Notifications',
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.notifications);
                        },
                        icon: const Icon(Icons.notifications_outlined),
                      ),
                      if (count > 0)
                        Positioned(
                          right: s.size(10),
                          top: s.size(10),
                          child: Container(
                            padding: EdgeInsets.all(s.size(4)),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: s.size(10),
                              minHeight: s.size(10),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
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
                  Navigator.of(context).pushNamed(AppRoutes.imageUploadTest);
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
        onDestinationSelected: (i) async {
          if (i == 2) {
            // Create tab acts as central action: open create post
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final posted = await navigator.pushNamed<bool>(
              AppRoutes.createPost,
            );
            if (!mounted) return;
            if (posted == true) {
              // switch to Profile tab and show toast
              setState(() => _currentIndex = 3);
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Post published'),
                  duration: const Duration(
                    seconds: 3,
                  ), // Auto-dismiss after 3 seconds
                  action: SnackBarAction(
                    label: 'View Profile',
                    onPressed: () => setState(() => _currentIndex = 3),
                  ),
                ),
              );
            }
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
