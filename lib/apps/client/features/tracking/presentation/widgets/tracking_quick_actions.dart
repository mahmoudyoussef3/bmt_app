import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// Three quick-action shortcuts shown before the trip starts: view route,
/// contact the driver, and reach support.
class TrackingQuickActions extends StatelessWidget {
  const TrackingQuickActions({
    super.key,
    required this.onViewRoute,
    required this.onContactDriver,
    required this.onSupport,
  });

  final VoidCallback onViewRoute;
  final VoidCallback onContactDriver;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickActionItem(
            icon: Icons.map_outlined,
            label: 'View Route',
            color: ClientColors.primary,
            onTap: onViewRoute,
          ),
          _QuickActionItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Contact Driver',
            color: ClientColors.journeyGreen,
            onTap: onContactDriver,
          ),
          _QuickActionItem(
            icon: Icons.support_agent_rounded,
            label: 'Support',
            color: scheme.tertiary,
            onTap: onSupport,
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(50)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
