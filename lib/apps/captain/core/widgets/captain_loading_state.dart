import 'package:flutter/material.dart';
import '../theme/captain_spacing.dart';

class CaptainSkeleton extends StatefulWidget {
  const CaptainSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<CaptainSkeleton> createState() => _CaptainSkeletonState();
}

class _CaptainSkeletonState extends State<CaptainSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              scheme.surfaceContainerHighest.withAlpha(100),
              scheme.surfaceContainerHighest.withAlpha(200),
              _controller.value,
            ),
            borderRadius: widget.borderRadius ?? CaptainRadius.rSm,
          ),
        );
      },
    );
  }
}
