import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

/// Boarding QR placeholder (UI only).
class TripQrCard extends StatelessWidget {
  const TripQrCard({super.key, required this.reference, this.size = 160});

  final String reference;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppSurface(
      padding: const EdgeInsets.all(20),
      radius: 22,
      child: Column(
        children: [
          Text(
            'Boarding pass',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            reference,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withAlpha(170),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline.withAlpha(80)),
            ),
            child: CustomPaint(
              painter: _QrPlaceholderPainter(color: scheme.onSurface),
              child: Center(
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 48,
                  color: scheme.onSurface.withAlpha(200),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Show this code when boarding',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withAlpha(160),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPlaceholderPainter extends CustomPainter {
  _QrPlaceholderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(25)
      ..style = PaintingStyle.fill;
    const cell = 12.0;
    for (double x = 0; x < size.width; x += cell) {
      for (double y = 0; y < size.height; y += cell) {
        if ((x / cell + y / cell).toInt().isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, cell - 2, cell - 2), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
