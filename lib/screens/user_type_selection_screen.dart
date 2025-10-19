import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user.dart';
import '../routes/app_routes.dart';
import '../services/user_service.dart';
import '../theme/theme.dart';

class UserTypeSelectionScreen extends StatefulWidget {

  const UserTypeSelectionScreen({
    super.key,
    required this.uid,
    required this.email,
    required this.fullName,
    this.profilePictureUrl,
  });
  final String uid;
  final String email;
  final String fullName;
  final String? profilePictureUrl;

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  UserRole? _selectedRole;
  bool _isCreating = false;

  final List<UserRoleOption> _roleOptions = [
    UserRoleOption(
      role: UserRole.artist,
      title: 'Artist/Creator',
      subtitle: 'Showcase your artwork and build your portfolio',
      icon: Icons.palette,
    ),
    UserRoleOption(
      role: UserRole.audience,
      title: 'Art Enthusiast',
      subtitle: 'Discover and support amazing artists',
      icon: Icons.favorite,
    ),
    UserRoleOption(
      role: UserRole.sponsor,
      title: 'Sponsor/Brand',
      subtitle: 'Support artists and collaborate on projects',
      icon: Icons.business,
    ),
    UserRoleOption(
      role: UserRole.organisation,
      title: 'Organization',
      subtitle: 'Host programs and connect with the art community',
      icon: Icons.apartment,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Role'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to ArtFolio!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'How would you like to use ArtFolio?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _roleOptions.length,
                itemBuilder: (context, index) {
                  final option = _roleOptions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedRole = option.role;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedRole == option.role
                                      ? AppColors.primary
                                      : Colors.grey,
                                  width: 2,
                                ),
                                color: _selectedRole == option.role
                                    ? AppColors.primary
                                    : Colors.transparent,
                              ),
                              child: _selectedRole == option.role
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        option.icon,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        option.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 36),
                                    child: Text(
                                      option.subtitle,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedRole != null && !_isCreating
                    ? _createUserAccount
                    : null,
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );

  Future<void> _createUserAccount() async {
    if (_selectedRole == null) return;

    setState(() {
      _isCreating = true;
    });

    try {
      await UserService.createUser(
        uid: widget.uid,
        email: widget.email,
        fullName: widget.fullName,
        role: _selectedRole!,
        profilePictureUrl: widget.profilePictureUrl,
      );

      if (mounted) {
        // Navigate to main app or show success
        unawaited(Navigator.of(context).pushReplacementNamed(AppRoutes.home));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}

class UserRoleOption {

  UserRoleOption({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final UserRole role;
  final String title;
  final String subtitle;
  final IconData icon;
}
