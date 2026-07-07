import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A compact icon+label action (Call, Chat, Track) inside [TripDriverCard].
class TripInlineActionButton extends StatelessWidget {
  const TripInlineActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: ClientColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ClientColors.primary.withAlpha(45)),
        ),
        child: Column(
          children: [
            Icon(icon, color: ClientColors.primary, size: 19),
            const SizedBox(height: 5),
            Text(
              label,
              style: ClientTypography.bodySmall(context).copyWith(
                color: ClientColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
