import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/session_state.dart';
import '../models/user.dart' as app_models;
import '../theme/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  app_models.UserRole _selectedRole = app_models.UserRole.audience;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isLogin) {
        await AuthService.instance.signInWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        // Sign up with email and create user profile
        final userCredential = await AuthService.instance.signUpWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

        if (userCredential.user != null) {
          await _createUserProfile(userCredential.user!);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = AuthService.instance.humanizeAuthError(e);
      });
    } catch (e) {
      setState(() {
        _error = 'Unexpected error: ${e.toString()}';
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  Future<void> _google() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userCredential = await AuthService.instance.signInWithGoogle();
      if (userCredential?.user != null) {
        // Check if user profile exists, if not create one
        final existingUser = await FirestoreService().getUser(
          userCredential!.user!.uid,
        );
        if (existingUser == null) {
          await _createUserProfile(userCredential.user!, isGoogleSignUp: true);
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Google sign-in failed: ${e.toString()}';
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  Future<void> _createUserProfile(
    User firebaseUser, {
    bool isGoogleSignUp = false,
  }) async {
    try {
      final now = DateTime.now();
      final username = isGoogleSignUp
          ? (firebaseUser.displayName?.replaceAll(' ', '').toLowerCase() ??
                'user${firebaseUser.uid.substring(0, 8)}')
          : _usernameCtrl.text.trim();

      final user = app_models.User(
        id: firebaseUser.uid,
        username: username,
        email: firebaseUser.email ?? '',
        fullName: isGoogleSignUp
            ? (firebaseUser.displayName ?? '')
            : _fullNameCtrl.text.trim(),
        profilePictureUrl: firebaseUser.photoURL ?? '',
        bio: '',
        role: isGoogleSignUp ? app_models.UserRole.audience : _selectedRole,
        createdAt: now,
        updatedAt: now,
      );

      await FirestoreService().createUser(user);
    } catch (e) {
      // Silently handle profile creation error but don't fail the auth
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authenticate'),
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
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.palette, size: 72, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  _isLogin ? 'Welcome back' : 'Create your account',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                if (_error != null) const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Enter email';
                          if (!RegExp(
                            r'^[^@]+@[^@]+\.[^@]+',
                          ).hasMatch(v.trim()))
                            return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (!_isLogin) ...[
                        TextFormField(
                          controller: _usernameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Enter username';
                            if (v.trim().length < 3)
                              return 'Username must be at least 3 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _fullNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Enter full name';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<app_models.UserRole>(
                          initialValue: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'I am a...',
                          ),
                          items: app_models.UserRole.values.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(
                                role.name.substring(0, 1).toUpperCase() +
                                    role.name.substring(1),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedRole = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _passwordCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter password';
                          if (v.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: Text(_isLogin ? 'Login' : 'Sign Up'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin
                              ? 'Need an account? Sign Up'
                              : 'Have an account? Login',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Expanded(child: Divider(color: scheme.outlineVariant)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('or'),
                    ),
                    Expanded(child: Divider(color: scheme.outlineVariant)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                    onPressed: _loading ? null : _google,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _loading
                      ? null
                      : () {
                          SessionState.instance.enterGuest();
                        },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Skip for now (Guest)'),
                ),
                if (_loading) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
