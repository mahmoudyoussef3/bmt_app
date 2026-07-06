import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_models.dart';

/// Builds a tappable station pin whose pointer tip sits exactly on the
/// coordinate. Start / destination pins are prominent; intermediate stops are
/// compact numbered dots. Pins scale-fade in (lightly staggered along the
/// route) and the selected pin elevates with a soft pulse.
Marker buildStationMarker(
  BuildContext context, {
  required RouteMapStop stop,
  required int index,
  required int count,
  required VoidCallback onTap,
  bool selected = false,
}) {
  final prominent = index == 0 || index == count - 1;
  final color = RouteMapStyle.colorFor(context, index, count);
  final label = RouteMapStyle.labelFor(index, count);

  return Marker(
    point: stop.coordinate,
    width: prominent ? 74 : 60,
    height: prominent ? 66 : 54,
    // Anchor the pointer tip exactly on the coordinate.
    alignment: Alignment.bottomCenter,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Route stop ${RouteMapStyle.roleFor(index, count)}',
        child: _MarkerEntrance(
          staggerIndex: index,
          child: _Pin(
            color: color,
            label: label,
            prominent: prominent,
            selected: selected,
          ),
        ),
      ),
    ),
  );
}

/// A floating card anchored above a pin, revealed when the stop is tapped.
Marker buildCalloutMarker(BuildContext context, {required RouteMapStop stop}) {
  return Marker(
    point: stop.coordinate,
    width: 210,
    height: 120,
    // Anchor at the coordinate; the card floats above the pin.
    alignment: Alignment.bottomCenter,
    child: _Callout(name: stop.name),
  );
}

/// One-shot scale + fade entrance, staggered a touch per stop so the route
/// "populates" instead of popping in. State survives rebuilds, so toggling a
/// callout never replays the entrance.
class _MarkerEntrance extends StatelessWidget {
  const _MarkerEntrance({required this.staggerIndex, required this.child});

  final int staggerIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delayMs = 60 * staggerIndex.clamp(0, 6);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 340 + delayMs),
      curve: Curves.easeOutBack,
      child: child,
      builder: (context, value, child) {
        final clamped = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: clamped,
          child: Transform.scale(
            scale: 0.55 + 0.45 * value,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({
    required this.color,
    required this.label,
    required this.prominent,
    required this.selected,
  });

  final Color color;
  final String label;
  final bool prominent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final diameter = prominent ? 40.0 : 30.0;
    final shadows = selected
        ? [
            BoxShadow(
              color: color.withAlpha(90),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ]
        : RouteMapStyle.shadow(context);

    return AnimatedScale(
      scale: selected ? 1.14 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (selected) _PulseHalo(color: color, diameter: diameter),
              Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, Color.lerp(color, Colors.black, 0.18)!],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: shadows,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: prominent ? 15 : 12,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          CustomPaint(
            size: Size(prominent ? 14 : 11, prominent ? 9 : 7),
            painter: _PinTailPainter(color),
          ),
        ],
      ),
    );
  }
}

/// A soft breathing ring behind the selected pin.
class _PulseHalo extends StatefulWidget {
  const _PulseHalo({required this.color, required this.diameter});

  final Color color;
  final double diameter;

  @override
  State<_PulseHalo> createState() => _PulseHaloState();
}

class _PulseHaloState extends State<_PulseHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

/// The small downward triangle that connects the pin body to its coordinate.
class _PinTailPainter extends CustomPainter {
  const _PinTailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter old) => old.color != color;
}

class _Callout extends StatelessWidget {
  const _Callout({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 6),
          child: child,
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 210),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: RouteMapStyle.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RouteMapStyle.border(context)),
            boxShadow: RouteMapStyle.shadow(context),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.place_rounded,
                size: 16,
                color: RouteMapStyle.stop(context),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  name.isEmpty ? 'Route stop' : name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
