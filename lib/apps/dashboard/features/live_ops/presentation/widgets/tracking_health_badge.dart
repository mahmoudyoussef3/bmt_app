import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/live_ops_snapshot.dart';
import 'live_ops_format.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// A pill that names a trip's tracking health and, for a live feed, pulses a
/// dot so the operator can tell at a glance which vehicles they can actually
/// see moving. The label carries the meaning; the colour and motion only
/// reinforce it (never colour-only).
class TrackingHealthBadge extends StatelessWidget {
  final TrackingHealth health;

  const TrackingHealthBadge({super.key, required this.health});

  @override
  Widget build(BuildContext context) {
    final colors = context.status(trackingHealthTone(health));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.tint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HealthDot(color: colors.ink, pulsing: health == TrackingHealth.live),
          const SizedBox(width: 6),
          Text(
            health.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthDot extends StatefulWidget {
  final Color color;
  final bool pulsing;

  const _HealthDot({required this.color, required this.pulsing});

  @override
  State<_HealthDot> createState() => _HealthDotState();
}

class _HealthDotState extends State<_HealthDot>
    with SingleTickerProviderStateMixin {
  /// Created eagerly, not lazily.
  ///
  /// A `late final` initializer here is a trap: a non-pulsing badge (stale,
  /// offline or unknown tracking — the states this screen exists to show) never
  /// touches the field in `initState`, `didUpdateWidget` or `build`, so the
  /// first access is `dispose()`. That constructs an `AnimationController`
  /// against an already-deactivated element and throws
  /// "Looking up a deactivated widget's ancestor is unsafe", crashing teardown
  /// whenever the operator navigates away with any non-live trip on screen.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      
      value: 1,
    );
    if (widget.pulsing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _HealthDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulsing && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 8.0;
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    if (!widget.pulsing) return dot;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
      child: dot,
    );
  }
}

/// Small, non-animated dot + label used inside dense KPI tiles.
class TrackingHealthTag extends StatelessWidget {
  final TrackingHealth health;

  const TrackingHealthTag({super.key, required this.health});

  @override
  Widget build(BuildContext context) {
    final colors = context.status(trackingHealthTone(health));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.tint,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        health.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
