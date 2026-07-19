import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_review_failure.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/utils/trip_review_failure_label.dart';

/// Inline banner for a review that failed to submit.
class TripReviewErrorBanner extends StatelessWidget {
  const TripReviewErrorBanner({super.key, required this.failure});

  final TripReviewFailure failure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClientColors.journeyRedLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: ClientColors.journeyRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tripReviewFailureLabel(context, failure),
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.onJourneyRed),
            ),
          ),
        ],
      ),
    );
  }
}
