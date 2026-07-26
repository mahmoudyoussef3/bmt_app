import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../cubit/captain_trip_map_state.dart';

/// The GPS traffic light: tells the captain, at a glance, whether their
/// position is really being tracked. A degraded feed offers a retry and never
/// masquerades as a working one.
class CaptainGpsHealthPill extends StatelessWidget {
  const CaptainGpsHealthPill({
    super.key,
    required this.health,
    required this.message,
    required this.onRetry,
  });

  final GpsHealth health;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = _presentation;
    final degraded =
        health == GpsHealth.lost || health == GpsHealth.unavailable;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s12,
        vertical: CaptainDesignTokens.s8,
      ),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.brPill,
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: CaptainDesignTokens.softShadow(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: color, pulsing: health == GpsHealth.live),
          const SizedBox(width: CaptainDesignTokens.s8),
          Flexible(
            child: Text(
              degraded && message != null ? message! : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.bodySmall(context).copyWith(
                color: CaptainColors.textPrimaryFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (degraded) ...[
            const SizedBox(width: CaptainDesignTokens.s8),
            InkWell(
              onTap: onRetry,
              borderRadius: CaptainDesignTokens.brPill,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.refresh_rounded, size: 18, color: color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color, IconData, String) get _presentation => switch (health) {
    GpsHealth.live => (
      CaptainColors.success,
      Icons.gps_fixed_rounded,
      'التتبع المباشر نشط',
    ),
    GpsHealth.acquiring => (
      CaptainColors.warning,
      Icons.gps_not_fixed_rounded,
      'جارٍ تحديد الموقع…',
    ),
    GpsHealth.lost => (
      CaptainColors.warning,
      Icons.gps_off_rounded,
      'انقطع الاتصال بالموقع',
    ),
    GpsHealth.unavailable => (
      CaptainColors.error,
      Icons.location_off_rounded,
      'الموقع غير متاح',
    ),
  };
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.pulsing});

  final Color color;
  final bool pulsing;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Dot old) {
    super.didUpdateWidget(old);
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
    return FadeTransition(
      opacity: widget.pulsing
          ? Tween<double>(begin: 0.35, end: 1).animate(_controller)
          : const AlwaysStoppedAnimation(1),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
