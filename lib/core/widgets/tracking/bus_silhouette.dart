import 'package:flutter/material.dart';

/// A compact bus silhouette (body + windshield band + two windows) — the
/// EasyWay vehicle identity, distinct from the generic
/// [Icons.directions_bus_rounded] glyph used everywhere else.
class BusSilhouette extends StatelessWidget {
  const BusSilhouette({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _BusSilhouettePainter());
  }
}

class _BusSilhouettePainter extends CustomPainter {
  const _BusSilhouettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = Colors.white;
    final glass = Paint()..color = Colors.white.withAlpha(130);

    final bodyRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.shortestSide * 0.28),
    );
    canvas.drawRRect(bodyRect, body);

    // Windshield band across the top third.
    final bandRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.14,
        size.width * 0.8,
        size.height * 0.24,
      ),
      Radius.circular(size.shortestSide * 0.12),
    );
    canvas.drawRRect(bandRect, glass);

    // Two window squares below the band.
    final windowWidth = size.width * 0.28;
    final windowHeight = size.height * 0.22;
    final windowY = size.height * 0.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.12, windowY, windowWidth, windowHeight),
        Radius.circular(size.shortestSide * 0.08),
      ),
      glass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.6, windowY, windowWidth, windowHeight),
        Radius.circular(size.shortestSide * 0.08),
      ),
      glass,
    );
  }

  @override
  bool shouldRepaint(covariant _BusSilhouettePainter oldDelegate) => false;
}
