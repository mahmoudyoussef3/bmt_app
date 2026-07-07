import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_layers.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_path_math.dart';
import 'package:bmt_app/core/theme/motion_preference.dart';

/// Draws the route with a progressive reveal: the line traces from origin to
/// destination while the glow, casing and main stroke fade in staggered — no
/// sudden appearance when road geometry arrives.
///
/// Cumulative segment lengths are computed once per path (never per frame),
/// and once the animation completes this renders a plain static layer.
class AnimatedRouteLine extends StatefulWidget {
  const AnimatedRouteLine({super.key, required this.coordinates});

  final List<LatLng> coordinates;

  @override
  State<AnimatedRouteLine> createState() => _AnimatedRouteLineState();
}

class _AnimatedRouteLineState extends State<AnimatedRouteLine>
    with SingleTickerProviderStateMixin {
  // Created in initState so the ticker never gets lazily instantiated
  // outside the widget's active lifecycle.
  late final AnimationController _controller;

  List<double> _cumulative = const [];

  static const _reveal = Interval(0, 1, curve: Curves.easeInOutCubic);
  static const _glowFade = Interval(0, 0.5, curve: Curves.easeOut);
  static const _casingFade = Interval(0.15, 0.7, curve: Curves.easeOut);
  static const _lineFade = Interval(0.3, 1, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _restart();
  }

  @override
  void didUpdateWidget(AnimatedRouteLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_samePath(oldWidget.coordinates, widget.coordinates)) _restart();
  }

  void _restart() {
    _cumulative = RoutePathMath.cumulativeDistances(widget.coordinates);
    if (AppMotion.reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  bool _samePath(List<LatLng> a, List<LatLng> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.coordinates.length < 2) return const SizedBox.shrink();

    if (AppMotion.reduceMotion) {
      return PolylineLayer(
        polylines: buildRoutePolylines(context, widget.coordinates),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final visible = RoutePathMath.pathPrefix(
          widget.coordinates,
          _cumulative,
          _reveal.transform(t),
        );
        return PolylineLayer(
          polylines: buildRoutePolylines(
            context,
            visible,
            glowOpacity: _glowFade.transform(t),
            casingOpacity: _casingFade.transform(t),
            lineOpacity: _lineFade.transform(t),
          ),
        );
      },
    );
  }
}
