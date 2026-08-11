import 'package:flutter/material.dart';

class CaptainAuthReveal extends StatefulWidget {
  const CaptainAuthReveal({super.key, required this.child, this.order = 0});

  final Widget child;

  final int order;

  @override
  State<CaptainAuthReveal> createState() => _CaptainAuthRevealState();
}

class _CaptainAuthRevealState extends State<CaptainAuthReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _start();
  }

  Future<void> _start() async {
    await Future<void>.delayed(Duration(milliseconds: 90 * widget.order));
    if (mounted) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        return Opacity(
          opacity: _curve.value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - _curve.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
