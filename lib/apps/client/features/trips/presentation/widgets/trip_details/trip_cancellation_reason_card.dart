import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_premium_panel.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_soft_icon.dart';

/// Shown when a trip has been cancelled, explaining why.
class TripCancellationReasonCard extends StatelessWidget {
  const TripCancellationReasonCard({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return TripPremiumPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TripSoftIcon(
            icon: Icons.cancel_outlined,
            color: ClientColors.journeyRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancellation Reason',
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(color: ClientColors.textPrimaryFor(context)),
                ),
                const SizedBox(height: 5),
                Text(
                  reason,
                  style: ClientTypography.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: ClientColors.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
