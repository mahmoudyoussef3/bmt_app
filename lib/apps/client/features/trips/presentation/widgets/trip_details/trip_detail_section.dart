import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A titled section wrapper (Route/Driver/Vehicle/Seats/Payment) inside
/// Trip Details.
class TripDetailSection extends StatelessWidget {
  const TripDetailSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ClientColors.borderFor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ClientColors.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: ClientColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ClientTypography.headingSmall(
                        context,
                      ).copyWith(color: ClientColors.textPrimaryFor(context)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: ClientColors.textSecondaryFor(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          child,
        ],
      ),
    );
  }
}
