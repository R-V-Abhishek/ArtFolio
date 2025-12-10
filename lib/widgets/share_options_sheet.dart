import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/share_service.dart';
import '../theme/scale.dart';

class ShareOptionsSheet extends StatelessWidget {
  const ShareOptionsSheet({
    super.key,
    this.post,
    this.user,
    this.onShareComplete,
  });

  final Post? post;
  final User? user;
  final VoidCallback? onShareComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = Scale(context);

    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(s.size(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.share_outlined,
                  size: s.size(24),
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: s.size(12)),
                Text(
                  'Share',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            SizedBox(height: s.size(16)),

            // Share options
            if (post != null) ...[
              _ShareOption(
                icon: Icons.share_outlined,
                title: 'Share Post',
                subtitle: 'Share this artwork with others',
                onTap: () => _sharePost(context),
              ),
              _ShareOption(
                icon: Icons.copy_outlined,
                title: 'Copy Link',
                subtitle: 'Copy post link to clipboard',
                onTap: () => _copyPostLink(context),
              ),
            ],

            if (user != null) ...[
              _ShareOption(
                icon: Icons.person_outline,
                title: 'Share Profile',
                subtitle: 'Share this artist\'s profile',
                onTap: () => _shareProfile(context),
              ),
              _ShareOption(
                icon: Icons.copy_outlined,
                title: 'Copy Profile Link',
                subtitle: 'Copy profile link to clipboard',
                onTap: () => _copyProfileLink(context),
              ),
            ],

            _ShareOption(
              icon: Icons.apps_outlined,
              title: 'Share ArtFolio',
              subtitle: 'Invite friends to join ArtFolio',
              onTap: () => _shareApp(context),
            ),

            SizedBox(height: s.size(16)),
          ],
        ),
      ),
    );
  }

  Future<void> _sharePost(BuildContext context) async {
    if (post == null) return;

    try {
      await ShareService.instance.sharePost(post!);
      onShareComplete?.call();

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post shared successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text('Could not share this post. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _shareProfile(BuildContext context) async {
    if (user == null) return;

    try {
      await ShareService.instance.shareProfile(user!);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile shared successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text('Could not share this profile. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    try {
      await ShareService.instance.shareApp();

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ArtFolio shared successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text('Could not share the app. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _copyPostLink(BuildContext context) async {
    if (post == null) return;

    // TODO: Implement copy to clipboard
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post link copied to clipboard!')),
      );
    }
  }

  Future<void> _copyProfileLink(BuildContext context) async {
    if (user == null) return;

    // TODO: Implement copy to clipboard
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile link copied to clipboard!')),
      );
    }
  }
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = Scale(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(s.size(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: s.size(12),
          horizontal: s.size(8),
        ),
        child: Row(
          children: [
            Container(
              width: s.size(48),
              height: s.size(48),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(s.size(12)),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: s.size(24),
              ),
            ),
            SizedBox(width: s.size(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: s.size(2)),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              size: s.size(20),
            ),
          ],
        ),
      ),
    );
  }
}
