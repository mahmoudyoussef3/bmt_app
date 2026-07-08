import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/motion_preference.dart';

/// A soft breathing ring behind a selected/active marker. Shared by station
/// pins and progress-state stop markers so the "this one is active" language
/// is identical everywhere on an EasyWay map.
class MapPulseHalo extends StatefulWidget {
  const MapPulseHalo({super.key, required this.color, required this.diameter});

  final Color color;
  final double diameter;

  @override
  State<MapPulseHalo> createState() => _MapPulseHaloState();
}

class _MapPulseHaloState extends State<MapPulseHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
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
    final reducedMotion = AppMotion.reduceMotion;
    if (reducedMotion) {
      return Container(
        width: widget.diameter * 1.12,
        height: widget.diameter * 1.12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withAlpha(42),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOut.transform(_controller.value);
        return Container(
          width: widget.diameter * (1 + t * 0.75),
          height: widget.diameter * (1 + t * 0.75),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withAlpha(((1 - t) * 70).round()),
          ),
        );
      },
    );
  }
}
