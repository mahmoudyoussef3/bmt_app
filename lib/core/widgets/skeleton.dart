import 'package:bmt_app/core/theme/motion_preference.dart';
import 'package:flutter/material.dart';

/// A single shimmering placeholder block used to build loading skeletons.
///
/// Unlike a static fill, [SkeletonBox] animates a soft highlight sweeping
/// across the box so loading states read as "working" rather than "frozen".
/// The public API (const constructor, [height]/[width]/[borderRadius]) is
/// unchanged, so every existing skeleton automatically gains the shimmer.
class SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.height = 12,
    this.width,
    this.borderRadius,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _shimmer = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _syncMotionPreference();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotionPreference();
  }

  void _syncMotionPreference() {
    if (AppMotion.reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(context).dividerColor;
    final base = divider.withAlpha(12);
    final highlight = Theme.of(context).colorScheme.primary.withAlpha(24);
    final radius = widget.borderRadius ?? BorderRadius.circular(8);

    if (AppMotion.reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(borderRadius: radius, color: base),
      );
    }

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [
              (_shimmer.value - 0.3).clamp(0.0, 1.0),
              _shimmer.value.clamp(0.0, 1.0),
              (_shimmer.value + 0.3).clamp(0.0, 1.0),
            ],
            colors: [base, highlight, base],
          ),
        ),
      ),
    );
  }
}
