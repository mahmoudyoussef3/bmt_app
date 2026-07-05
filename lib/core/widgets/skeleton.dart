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
    )..repeat();
    _shimmer = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(context).dividerColor;
    final base = divider.withAlpha(15);
    final highlight = divider.withAlpha(35);
    final radius = widget.borderRadius ?? BorderRadius.circular(8);

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
