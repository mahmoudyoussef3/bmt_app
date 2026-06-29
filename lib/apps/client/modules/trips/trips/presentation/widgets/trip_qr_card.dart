import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// Boarding QR placeholder (UI only).
class TripQrCard extends StatelessWidget {
  const TripQrCard({super.key, required this.reference, this.size = 160});

  final String reference;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        children: [
          Text(
            'Boarding pass',
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            reference,
            style: ClientTypography.bodySmall(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
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
              border: Border.all(color: ClientColors.borderFor(context)),
            ),
            child: CustomPaint(
              painter: _QrPlaceholderPainter(
                color: ClientColors.textPrimaryFor(context),
              ),
              child: Center(
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 48,
                  color: ClientColors.textSecondaryFor(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Show this code when boarding',
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
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
