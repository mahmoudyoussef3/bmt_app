import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';

/// A compact tinted fact on a history card — passengers, duration, vehicle.
class TripHistoryChip extends StatelessWidget {
  const TripHistoryChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s8,
        vertical: CaptainDesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: CaptainDesignTokens.br8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: CaptainDesignTokens.s4),
          // Flexible so the chip yields to a narrow card instead of running
          // past its edge: a plate and a shortfall line both grow with the
          // system font, and a `Row` measures a plain `Text` unbounded.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
