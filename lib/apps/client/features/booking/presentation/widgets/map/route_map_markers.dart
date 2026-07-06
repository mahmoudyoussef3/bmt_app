import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_models.dart';

/// Builds a tappable station pin whose pointer tip sits exactly on the
/// coordinate. Start / destination pins are prominent; intermediate stops are
/// compact numbered dots.
Marker buildStationMarker(
  BuildContext context, {
  required RouteMapStop stop,
  required int index,
  required int count,
  required VoidCallback onTap,
}) {
  final prominent = index == 0 || index == count - 1;
  final color = RouteMapStyle.colorFor(context, index, count);
  final label = RouteMapStyle.labelFor(index, count);

  return Marker(
    point: stop.coordinate,
    width: prominent ? 62 : 48,
    height: prominent ? 58 : 46,
    // Anchor the pointer tip exactly on the coordinate.
    alignment: Alignment.bottomCenter,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        label: 'Route stop ${RouteMapStyle.roleFor(index, count)}',
        child: _Pin(color: color, label: label, prominent: prominent),
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

class _Pin extends StatelessWidget {
  const _Pin({
    required this.color,
    required this.label,
    required this.prominent,
  });

  final Color color;
  final String label;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final diameter = prominent ? 40.0 : 30.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
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
            boxShadow: RouteMapStyle.shadow(context),
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
        CustomPaint(
          size: Size(prominent ? 14 : 11, prominent ? 9 : 7),
          painter: _PinTailPainter(color),
        ),
      ],
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
    return Align(
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
    );
  }
}
