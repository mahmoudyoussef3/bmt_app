import 'package:flutter/material.dart';

import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';

/// The design's empty state: a hatched placeholder square, a short headline,
/// and one line saying what will fill it.
///
/// The hatching is the point. A plain tinted circle behind an icon looks like a
/// button that failed to load; diagonal hatch reads, in every drawing
/// convention, as "nothing here yet" — which is exactly the message, and it
/// says it before the captain reads a word of Arabic.
class CaptainEmptyState extends StatelessWidget {
  const CaptainEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s24,
        vertical: CaptainDesignTokens.s32,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CaptainHatchedTile(icon: icon),
          const SizedBox(height: CaptainDesignTokens.s20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: CaptainTypography.titleSmall(context).copyWith(
              fontWeight: FontWeight.w800,
              color: CaptainColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: CaptainDesignTokens.s8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: CaptainTypography.bodySmall(context).copyWith(
                color: CaptainColors.textSecondaryFor(context),
                fontWeight: FontWeight.w600,
                height: 1.7,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: CaptainDesignTokens.s24),
            action!,
          ],
        ],
      ),
    );
  }
}

/// The hatched square an empty state is built around.
class CaptainHatchedTile extends StatelessWidget {
  const CaptainHatchedTile({super.key, required this.icon, this.size = 116});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final muted = CaptainColors.textSecondaryFor(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        border: CaptainDesignTokens.hairline(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _HatchPainter(color: CaptainColors.surfaceAltFor(context)),
        child: Center(
          child: Icon(icon, size: size * 0.34, color: muted),
        ),
      ),
    );
  }
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter({required this.color});

  final Color color;

  static const double _band = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _band
      ..style = PaintingStyle.stroke;

    // 45° bands drawn as strokes: start far enough off-canvas that the first
    // and last band cover the corners the diagonal would otherwise miss.
    for (var x = -size.height; x < size.width + size.height; x += _band * 2) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HatchPainter oldDelegate) => oldDelegate.color != color;
}
