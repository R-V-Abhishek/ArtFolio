import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/auth_service.dart';
import '../services/session_state.dart';
import '../theme/scale.dart';
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
  // Flag to show/hide guest option (disabled for now)
  static const bool _showGuestOption = false;
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  // Role selection happens on a dedicated screen after signup
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email to receive a reset link.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.instance.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.instance.humanizeAuthError(e));
    } catch (e) {
      setState(() => _error = 'Failed to send reset email: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        _error = 'Unexpected error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential = await AuthService.instance.signInWithGoogle();
      if (credential?.user != null) {
        // Let the AuthStateHandler handle navigation
        // The auth state change will trigger the proper flow
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _createUserProfile(User firebaseUser) async {
    // No-op: do not create the user document here.
    // AuthStateHandler will detect missing profile and route to
    // UserTypeSelectionScreen for both Google and email sign-ups.
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = Scale(context);
    return Scaffold(
      // Ensure the Scaffold resizes when the keyboard appears
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/logo.svg',
              height: s.size(28),
              semanticsLabel: 'ArtFolio',
            ),
            SizedBox(width: s.size(10)),
            Text(
              'ArtFolio',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                // More artistic weight and size for brand title
                fontSize: s.font(30),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: themeController.toggle,
            icon: Icon(
              themeController.value == ThemeMode.dark
                  ? Icons.nightlight_round
                  : Icons.wb_sunny,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  s.size(20),
                  s.size(20),
                  s.size(20),
                  s.size(20) + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: s.size(20),
                      vertical: s.size(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title only (remove colored square/icon next to text)
                        Center(
                          child: Text(
                            _isLogin ? 'Welcome back' : 'Create your account',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        SizedBox(height: s.size(16)),
                        if (_error != null)
                          Container(
                            padding: EdgeInsets.all(s.size(12)),
                            decoration: BoxDecoration(
                              color: scheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(color: scheme.onErrorContainer),
                            ),
                          ),
                        if (_error != null) SizedBox(height: s.size(12)),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Enter email';
                                  }
                                  if (!RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+',
                                  ).hasMatch(v.trim())) {
                                    return 'Invalid email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: s.size(16)),
                              if (!_isLogin) ...[
                                TextFormField(
                                  controller: _usernameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Enter username';
                                    }
                                    if (v.trim().length < 3) {
                                      return 'Username must be at least 3 characters';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: s.size(16)),
                                TextFormField(
                                  controller: _fullNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Enter full name';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: s.size(16)),
                                // Role selection removed (handled after signup)
                                SizedBox(height: s.size(16)),
                              ],
                              TextFormField(
                                controller: _passwordCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: StatefulBuilder(
                                    builder: (context, setIconState) =>
                                        IconButton(
                                          tooltip: 'Show/Hide password',
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () {
                                            setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            );
                                            setIconState(() {});
                                          },
                                        ),
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Enter password';
                                  }
                                  if (v.length < 6) {
                                    return 'Min 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: s.size(8)),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _loading ? null : _forgotPassword,
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                              SizedBox(height: s.size(24)),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _loading ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: s.size(16),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(_isLogin ? 'Login' : 'Sign Up'),
                                ),
                              ),
                              SizedBox(height: s.size(12)),
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () =>
                                          setState(() => _isLogin = !_isLogin),
                                child: Text(
                                  _isLogin
                                      ? 'Need an account? Sign Up'
                                      : 'Have an account? Login',
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: s.size(20)),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Divider(color: scheme.outlineVariant),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: s.size(8),
                              ),
                              child: const Text('or'),
                            ),
                            Expanded(
                              child: Divider(color: scheme.outlineVariant),
                            ),
                          ],
                        ),
                        SizedBox(height: s.size(12)),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: SvgPicture.asset(
                              'assets/icons/google_g_multicolor.svg',
                              height: s.size(20),
                              semanticsLabel: 'Google',
                            ),
                            label: const Text('Continue with Google'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: s.size(14),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _loading ? null : _signInWithGoogle,
                          ),
                        ),
                        SizedBox(height: s.size(12)),
                        // Guest option completely hidden but preserved for routing
                        Visibility(
                          visible: _showGuestOption,
                          child: TextButton.icon(
                            onPressed: _loading
                                ? null
                                : SessionState.instance.enterGuest,
                            icon: const Icon(Icons.visibility),
                            label: const Text('Skip for now (Guest)'),
                          ),
                        ),
                        if (_loading) ...[
                          SizedBox(height: s.size(16)),
                          const Center(child: CircularProgressIndicator()),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
