import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/account_deletion_service.dart';
import '../routes/app_routes.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  bool _isDeleting = false;
  bool _confirmDeletion = false;
  Map<String, int>? _deletionSummary;
  bool _loadingSummary = true;

  @override
  void initState() {
    super.initState();
    _loadDeletionSummary();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadDeletionSummary() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final summary = await AccountDeletionService.getAccountDeletionSummary(
          userId,
        );
        setState(() {
          _deletionSummary = summary;
          _loadingSummary = false;
        });
      }
    } catch (e) {
      setState(() {
        _loadingSummary = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    if (!_confirmDeletion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm that you want to delete your account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Re-authenticate user for security
      if (_passwordController.text.isNotEmpty) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _passwordController.text,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // Check if user can delete account
      final canDelete = await AccountDeletionService.canDeleteAccount(user.uid);
      if (!canDelete) {
        throw Exception('Account deletion not allowed');
      }

      // Show final confirmation dialog
      final confirmed = await _showFinalConfirmationDialog();
      if (!confirmed) {
        setState(() {
          _isDeleting = false;
        });
        return;
      }

      // Delete the account
      await AccountDeletionService.deleteAccount(user.uid);

      // Navigate to auth screen
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.auth, (route) => false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on RecentLoginRequiredException catch (_) {
      // Handle the case where re-authentication is required
      if (mounted) {
        final shouldRetry = await _showReauthenticationDialog();
        if (shouldRetry) {
          // Retry deletion after successful re-authentication
          _deleteAccount();
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Authentication failed';
      if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<bool> _showFinalConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Final Confirmation'),
              content: const Text(
                'This action is IRREVERSIBLE. All your data will be permanently deleted. '
                'Are you absolutely sure you want to delete your account?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Yes, Delete Forever'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _showReauthenticationDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Check if user signed in with Google
    final providerData = user.providerData;
    final hasGoogleProvider = providerData.any(
      (provider) => provider.providerId == 'google.com',
    );

    if (hasGoogleProvider) {
      // For Google users, show a dialog explaining they need to re-authenticate
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Re-authentication Required'),
            content: const Text(
              'For security, you need to sign in again with Google before deleting your account.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await AccountDeletionService.reauthenticateUser();
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.of(context).pop(false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Re-authentication failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Sign in with Google'),
              ),
            ],
          );
        },
      );
      return result ?? false;
    } else {
      // For email/password users, show password input dialog
      final passwordController = TextEditingController();
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Re-authentication Required'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('For security, please enter your password again:'),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  passwordController.dispose();
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await AccountDeletionService.reauthenticateUser(
                      email: user.email,
                      password: passwordController.text,
                    );
                    passwordController.dispose();
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  } catch (e) {
                    passwordController.dispose();
                    if (context.mounted) {
                      Navigator.of(context).pop(false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Re-authentication failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
      return result ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
        backgroundColor: Colors.red.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Danger Zone',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Deleting your account is permanent and cannot be undone. '
                    'All your data will be permanently removed from our servers.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Data Summary
            Text(
              'What will be deleted:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            if (_loadingSummary)
              const Center(child: CircularProgressIndicator())
            else if (_deletionSummary != null) ...[
              _buildDataSummaryCard(),
              const SizedBox(height: 24),
            ],

            // Password Re-authentication
            if (user?.providerData.any(
                  (info) => info.providerId == 'password',
                ) ==
                true) ...[
              Text(
                'Confirm your password:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                enabled: !_isDeleting,
              ),
              const SizedBox(height: 24),
            ],

            // Confirmation Checkbox
            CheckboxListTile(
              value: _confirmDeletion,
              onChanged: _isDeleting
                  ? null
                  : (value) {
                      setState(() {
                        _confirmDeletion = value ?? false;
                      });
                    },
              title: const Text(
                'I understand that this action is permanent and irreversible',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 24),

            // Delete Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isDeleting ? null : _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'DELETE MY ACCOUNT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Alternative options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not sure about deleting?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Consider these alternatives:\n'
                      '• Log out temporarily\n'
                      '• Update your privacy settings\n'
                      '• Contact support for help',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Data Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...(_deletionSummary?.entries.map((entry) {
                  final icon = _getIconForDataType(entry.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(icon, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Text('${entry.value} ${entry.key}'),
                      ],
                    ),
                  );
                }).toList() ??
                []),
            const Divider(),
            const Text(
              'All of this data will be permanently deleted.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForDataType(String dataType) {
    switch (dataType) {
      case 'posts':
        return Icons.image;
      case 'comments':
        return Icons.comment;
      case 'likes':
        return Icons.favorite;
      case 'following':
      case 'followers':
        return Icons.people;
      default:
        return Icons.data_object;
    }
  }
}
