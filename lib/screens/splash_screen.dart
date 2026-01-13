import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.next, this.durationMs = 2500});

  final Widget next;
  final int durationMs;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _floatingController;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _slideUp;
  late final Animation<double> _floating;
  Timer? _timer;
  bool _done = false;

  // Logo color palette
  static const goldenYellow = Color(0xFFE2B444);
  static const tealGreen = Color(0xFF60C4AE);
  static const coralRed = Color(0xFFE85D52);
  static const darkTeal = Color(0xFF155E5C);
  static const deepNeutral = Color(0xFF3F3029);

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Floating animation controller for subtle movement
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1, curve: Curves.easeOutCubic),
      ),
    );

    _floating = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _controller.forward();

    _timer = Timer(Duration(milliseconds: widget.durationMs), () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.next;

    return Scaffold(
      body: Stack(
        children: [
          // Elegant gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  darkTeal,
                  darkTeal.withValues(alpha: 0.95),
                  deepNeutral,
                ],
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -100,
            right: -100,
            child: FadeTransition(
              opacity: _fade,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tealGreen.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: FadeTransition(
              opacity: _fade,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: coralRed.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with animations
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _controller,
                    _floatingController,
                  ]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floating.value),
                      child: ScaleTransition(
                        scale: _scale,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                            boxShadow: [
                              BoxShadow(
                                color: goldenYellow.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/icons/logo.png',
                            height: 100,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // App name with gradient
                FadeTransition(
                  opacity: _fade,
                  child: AnimatedBuilder(
                    animation: _slideUp,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideUp.value),
                        child: child,
                      );
                    },
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [goldenYellow, tealGreen],
                      ).createShader(bounds),
                      child: const Text(
                        'ArtFolio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tagline
                FadeTransition(
                  opacity: _fade,
                  child: AnimatedBuilder(
                    animation: _slideUp,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideUp.value + 10),
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: coralRed.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'Showcase. Connect. Inspire.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
