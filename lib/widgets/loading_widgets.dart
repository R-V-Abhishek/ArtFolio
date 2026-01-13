import 'package:flutter/material.dart';

/// A widget that wraps content and shows a loading overlay when needed
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
    this.overlayColor,
  });
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  final Color? overlayColor;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      if (isLoading)
        ColoredBox(
          color: overlayColor ?? Colors.black.withValues(alpha: 0.3),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
    ],
  );
}

/// A simplified loading widget for buttons
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.isLoading,
    this.loadingText,
    this.style,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final String? loadingText;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: isLoading ? null : onPressed,
    style: style,
    child: isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              if (loadingText != null) ...[
                const SizedBox(width: 8),
                Text(loadingText!),
              ],
            ],
          )
        : child,
  );
}

/// A widget that shows loading indicator in place of content
class LoadingPlaceholder extends StatelessWidget {
  const LoadingPlaceholder({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingWidget,
    this.loadingMessage,
  });
  final bool isLoading;
  final Widget child;
  final Widget? loadingWidget;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ?? _buildDefaultLoading(context);
    }

    return child;
  }

  Widget _buildDefaultLoading(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        if (loadingMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            loadingMessage!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    ),
  );
}

/// Shimmer loading effect for list items
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
  });
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final baseColor =
        widget.baseColor ??
        (theme.brightness == Brightness.dark
            ? Colors.grey[800]!
            : Colors.grey[300]!);
    final highlightColor =
        widget.highlightColor ??
        (theme.brightness == Brightness.dark
            ? Colors.grey[700]!
            : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [baseColor, highlightColor, baseColor],
          stops: [
            (_animation.value - 0.3).clamp(0.0, 1.0),
            _animation.value.clamp(0.0, 1.0),
            (_animation.value + 0.3).clamp(0.0, 1.0),
          ],
        ).createShader(bounds),
        child: widget.child,
      ),
    );
  }
}
