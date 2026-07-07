import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A compact stat pill inside [TripsHeader] (e.g. "Upcoming: 3").
class TripStatChip extends StatelessWidget {
  const TripStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ClientColors.textInverse.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ClientColors.textInverse.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ClientColors.textInverse),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textInverse),
              ),
              Text(
                value,
                style: ClientTypography.labelLarge(
                  context,
                ).copyWith(color: ClientColors.textInverse),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
