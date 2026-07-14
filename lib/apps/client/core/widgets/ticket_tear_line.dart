import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/dashed_divider.dart';

/// The tear line of a boarding pass: a punched notch on each edge of the card
/// with a dashed rule between them.
///
/// It splits what a trip *is* from what it *costs*, so the fare and the action
/// read as their own zone — without breaking the card into two separate
/// objects. Used by the home trip card and the checkout ticket.
///
/// [fill] must match the surface the card sits on, otherwise the punched holes
/// show the wrong color. Defaults to the page background.
class TicketTearLine extends StatelessWidget {
  const TicketTearLine({
    super.key,
    this.radius = 9,
    this.inset = 0,
    this.fill,
  });

  final double radius;

  /// The card's own horizontal padding. A tear line laid inside a padded card
  /// has to travel back across that padding for its notches to land on the
  /// card's edge. Leave at `0` when the tear line already spans edge to edge.
  final double inset;

  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final holeFill = fill ?? ClientColors.backgroundFor(context);
    final border = ClientColors.borderFor(context);

    return SizedBox(
      height: radius * 2,
      child: Row(
        children: [
          _Notch(
            radius: radius,
            fill: holeFill,
            border: border,
            centerAtLeft: !isRtl,
            dx: isRtl ? inset : -inset,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ClientSpacing.sm),
              child: DashedDivider(color: border),
            ),
          ),
          _Notch(
            radius: radius,
            fill: holeFill,
            border: border,
            centerAtLeft: isRtl,
            dx: isRtl ? -inset : inset,
          ),
        ],
      ),
    );
  }
}

/// Half a punched hole. The circle is centred on the card's border so the fill
/// erases the border where the hole sits, and only the arc facing the card's
/// inside is stroked back in.
class _Notch extends StatelessWidget {
  const _Notch({
    required this.radius,
    required this.fill,
    required this.border,
    required this.centerAtLeft,
    required this.dx,
  });

  final double radius;
  final Color fill;
  final Color border;
  final bool centerAtLeft;

  /// Horizontal travel out to the card's edge, in physical left/right terms —
  /// the caller has already resolved it against the text direction.
  final double dx;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(dx, 0),
      child: CustomPaint(
        size: Size(radius, radius * 2),
        painter: _NotchPainter(
          radius: radius,
          fill: fill,
          border: border,
          centerAtLeft: centerAtLeft,
        ),
      ),
    );
  }
}

class _NotchPainter extends CustomPainter {
  const _NotchPainter({
    required this.radius,
    required this.fill,
    required this.border,
    required this.centerAtLeft,
  });

  final double radius;
  final Color fill;
  final Color border;
  final bool centerAtLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(centerAtLeft ? 0 : size.width, size.height / 2);
    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      centerAtLeft ? -math.pi / 2 : math.pi / 2,
      math.pi,
      false,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_NotchPainter old) =>
      old.radius != radius ||
      old.fill != fill ||
      old.border != border ||
      old.centerAtLeft != centerAtLeft;
}
