import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/art_piece.dart';
import '../widgets/art_card.dart';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 1200
              ? 6
              : constraints.maxWidth > 900
              ? 5
              : constraints.maxWidth > 700
              ? 4
              : constraints.maxWidth > 500
              ? 3
              : 2;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isGuest
                                  ? 'Exploring as Guest'
                                  : 'Welcome back, ${user.email ?? 'Creator'}!',
                              style: Theme.of(context).textTheme.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isGuest
                            ? 'Browse amazing artwork from our community'
                            : 'Discover and share creative inspiration',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(12.0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3 / 4,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ArtCard(piece: ArtPiece.dummy[index]),
                    childCount: ArtPiece.dummy.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
