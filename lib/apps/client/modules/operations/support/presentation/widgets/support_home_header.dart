import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

class SupportHomeHeader extends StatelessWidget {
  const SupportHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ClientColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.support_agent,
                color: ClientColors.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'How can we help?',
                style: ClientTypography.headingMedium(
                  context,
                ).copyWith(color: ClientColors.textPrimaryFor(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Our support team is available 24/7 to assist you with any issues related to your bookings, trips, or account.',
            style: ClientTypography.bodySmall(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
