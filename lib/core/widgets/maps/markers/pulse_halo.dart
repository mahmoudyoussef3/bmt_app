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
    if (AppMotion.reduceMotion) {
      return _layoutNeutral(_ring(1.12, 42));
    }
    return _layoutNeutral(
      AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_controller.value);
          return _ring(1 + t * 0.75, ((1 - t) * 70).round());
        },
      ),
    );
  }

  Widget _ring(double scale, int alpha) => Container(
    width: widget.diameter * scale,
    height: widget.diameter * scale,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: widget.color.withAlpha(alpha),
    ),
  );

  /// The ring breathes out past [MapPulseHalo.diameter], but only [diameter] is
  /// ever reported to the parent. Letting the animated size reach layout made
  /// the marker it sits in overflow on the wide half of every pulse (the
  /// yellow-and-black "RenderFlex overflowed" banner on the map) and shifted
  /// the pin as it breathed. The ring still *paints* at full width — every host
  /// Stack uses `clipBehavior: Clip.none`.
  Widget _layoutNeutral(Widget ring) => SizedBox.square(
    dimension: widget.diameter,
    child: OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: ring,
    ),
  );
}
