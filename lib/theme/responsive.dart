import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Breakpoints based on common Material guidance.
class Breakpoints {
  static const double compact = 0; // phones
  static const double medium = 600; // large phones / small tablets
  static const double expanded = 1024; // tablets / desktop
}

enum SizeClass { compact, medium, expanded }

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  SizeClass get sizeClass {
    final w = screenWidth;
    if (w >= Breakpoints.expanded) return SizeClass.expanded;
    if (w >= Breakpoints.medium) return SizeClass.medium;
    return SizeClass.compact;
  }

  bool get isCompact => sizeClass == SizeClass.compact;
  bool get isMedium => sizeClass == SizeClass.medium;
  bool get isExpanded => sizeClass == SizeClass.expanded;

  /// Default horizontal padding to keep content breathable at each size class.
  EdgeInsets get horizontalPadding {
    switch (sizeClass) {
      case SizeClass.compact:
        return const EdgeInsets.symmetric(horizontal: 16);
      case SizeClass.medium:
        return const EdgeInsets.symmetric(horizontal: 20);
      case SizeClass.expanded:
        return const EdgeInsets.symmetric(horizontal: 24);
    }
  }
}

/// A lightweight wrapper that centers content and constrains its max width
/// on larger screens. On phones, it keeps full-bleed layouts.
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({super.key, required this.child, this.maxWidth});

  /// The widget tree for the current route.
  final Widget child;

  /// Optional override for max content width on large screens.
  final double? maxWidth;

  static double _defaultMaxWidth(SizeClass size) {
    switch (size) {
      case SizeClass.compact:
        return double.infinity; // no constraint
      case SizeClass.medium:
        return 720; // comfortable reading width
      case SizeClass.expanded:
        return 1000; // wide but not edge-to-edge
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sizeClass;
    final targetMax = maxWidth ?? _defaultMaxWidth(sc);

    if (sc == SizeClass.compact) {
      // Keep native phone layout untouched
      return child;
    }

    // On wider screens, center the route and clamp the width so content
    // adapts automatically without per-screen tweaks.
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.max(0, targetMax)),
          child: Padding(
            padding: context.horizontalPadding.copyWith(top: 0, bottom: 0),
            child: child,
          ),
        ),
      ),
    );
  }
}
