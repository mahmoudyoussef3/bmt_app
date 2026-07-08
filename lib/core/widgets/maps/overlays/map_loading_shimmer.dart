import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/motion_preference.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';
import 'package:bmt_app/core/widgets/skeleton.dart';

/// Full-bleed map loading state: a shimmering skeleton (reusing the app's
/// established [SkeletonBox] primitive, not a new shimmer implementation)
/// plus a route-tracing dot sweep. Replaces every bare [CircularProgressIndicator]
/// on a map surface — loading should read as "tracing your route", not frozen.
class MapLoadingShimmer extends StatelessWidget {
  const MapLoadingShimmer({super.key, this.message = 'Tracing your route…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(70),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SkeletonBox(
              width: 180,
              height: 6,
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
            const SizedBox(height: 18),
            const _RouteTraceDots(),
            const SizedBox(height: 10),
            Text(
              message,
              style: MapStyle.pillLabel(
                context,
              ).copyWith(color: MapStyle.onSurfaceMuted(context)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three dots pulsing in sequence like a route being traced left to right.
class _RouteTraceDots extends StatefulWidget {
  const _RouteTraceDots();

  @override
  State<_RouteTraceDots> createState() => _RouteTraceDotsState();
}

class _RouteTraceDotsState extends State<_RouteTraceDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (AppMotion.reduceMotion) {
      _controller.value = 1;
    } else {
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
    final color = MapStyle.routeLine(context);
    if (AppMotion.reduceMotion) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => _dot(color, 1)),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value - i * 0.22) % 1.0;
            final scale = 0.5 + 0.5 * (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
            return _dot(color, scale);
          }),
        );
      },
    );
  }

  Widget _dot(Color color, double scale) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Transform.scale(
      scale: scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    ),
  );
}
