import 'package:flutter/material.dart';

/// Responsive scaling utility for text, icons, and spacing.
///
/// Baseline width is 375 (typical mobile). Scale is clamped for sanity.
class Scale {

  Scale(this.context) {
    final width = MediaQuery.of(context).size.width;
    _scale = width / 375.0;
  }
  final BuildContext context;
  late final double _scale;

  /// Scales font sizes; clamp to avoid extremes.
  double font(double size) => size * _scale.clamp(0.8, 1.4);

  /// Scales generic sizes (icons, widget dimensions).
  double size(double value) => value * _scale.clamp(0.8, 1.4);

  /// Scales symmetric horizontal spacing while preserving vertical as-is.
  EdgeInsets horizontal(double h) =>
      EdgeInsets.symmetric(horizontal: h * _scale.clamp(0.8, 1.4));

  /// Scales uniform padding.
  EdgeInsets spacing(double all) =>
      EdgeInsets.all(all * _scale.clamp(0.8, 1.4));
}
