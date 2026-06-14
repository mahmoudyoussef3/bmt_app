import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBackgroundBlob extends StatefulWidget {
  final Color color;
  final double size;
  final Offset initialPosition;
  final Duration animationDuration;

  const AnimatedBackgroundBlob({
    super.key,
    required this.color,
    required this.size,
    required this.initialPosition,
    this.animationDuration = const Duration(seconds: 10),
  });

  @override
  State<AnimatedBackgroundBlob> createState() => _AnimatedBackgroundBlobState();
}

class _AnimatedBackgroundBlobState extends State<AnimatedBackgroundBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  late double _offsetX;
  late double _offsetY;

  @override
  void initState() {
    super.initState();
    _offsetX = widget.initialPosition.dx;
    _offsetY = widget.initialPosition.dy;

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine);

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate slow drifting movement based on animation value
    final currentX = _offsetX + (math.sin(_animation.value * math.pi * 2) * 50);
    final currentY = _offsetY + (math.cos(_animation.value * math.pi * 2) * 50);
    final currentScale = 1.0 + (_animation.value * 0.2);

    return Positioned(
      left: currentX,
      top: currentY,
      child: Transform.scale(
        scale: currentScale,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.3),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.2),
                blurRadius: 100,
                spreadRadius: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
