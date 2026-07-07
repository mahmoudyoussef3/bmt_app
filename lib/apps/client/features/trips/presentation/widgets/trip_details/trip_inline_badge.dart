import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A small colored pill for a status word (vehicle type, payment state,
/// "Ready", ...) inside Trip Details' cards.
class TripInlineBadge extends StatelessWidget {
  const TripInlineBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: ClientTypography.labelSmall(context).copyWith(color: color),
      ),
    );
  }
}
