import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// The tear line across the boarding pass: two notches punched out of the
/// card's edges, joined by a dashed rule.
///
/// The notches are drawn in the page's background color and sit half outside
/// the card, so they read as holes bitten into it. [inset] is the card's own
/// horizontal padding — the notch has to travel back across it to land on the
/// card's edge.
class TicketTearLine extends StatelessWidget {
  const TicketTearLine({super.key, required this.inset});

  final double inset;

  static const double _radius = 11;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DashedRulePainter(
                color: ClientColors.borderStrongFor(context),
              ),
            ),
          ),
          PositionedDirectional(start: -inset - _radius, child: const _Notch()),
          PositionedDirectional(end: -inset - _radius, child: const _Notch()),
        ],
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: TicketTearLine._radius * 2,
      height: TicketTearLine._radius * 2,
      decoration: BoxDecoration(
        color: ClientColors.backgroundFor(context),
        shape: BoxShape.circle,
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
    );
  }
}

class _DashedRulePainter extends CustomPainter {
  const _DashedRulePainter({required this.color});

  final Color color;

  static const double _dash = 6;
  static const double _gap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    // Start clear of the notches so the dashes never run under them.
    for (var x = 6.0; x < size.width - 6; x += _dash + _gap) {
      final end = (x + _dash).clamp(0.0, size.width - 6);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRulePainter oldDelegate) =>
      oldDelegate.color != color;
}
