import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// One seat tile inside [MiniSeatLayout].
class MiniSeatBox extends StatelessWidget {
  const MiniSeatBox({super.key, required this.number, required this.selected});

  final String number;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? ClientColors.journeyGreen
        : ClientColors.primary.withAlpha(92);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 46,
      height: 42,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: ClientColors.journeyGreen.withAlpha(60),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          number,
          style: ClientTypography.labelMedium(context).copyWith(
            color: ClientColors.textInverse,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

/// A small color+label legend entry describing what a seat color means.
class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: ClientTypography.bodySmall(context).copyWith(
            fontWeight: FontWeight.w800,
            color: ClientColors.textPrimaryFor(context),
          ),
        ),
      ],
    );
  }
}
