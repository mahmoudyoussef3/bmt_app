import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';

/// A payment-status pill (paid/pending/under review/refunded/failed) on a
/// trip card, with a distinct bg/fg color pair per status.
class TripPaymentChip extends StatelessWidget {
  const TripPaymentChip({super.key, required this.label, required this.status});

  final String label;
  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      PaymentStatus.paid => (
        ClientColors.journeyGreenLight,
        ClientColors.onJourneyGreen,
      ),
      PaymentStatus.pending => (
        ClientColors.journeyAmberLight,
        ClientColors.onJourneyAmber,
      ),
      PaymentStatus.underReview => (
        ClientColors.journeyAmberLight,
        ClientColors.onJourneyAmber,
      ),
      PaymentStatus.failed => (
        ClientColors.journeyRedLight,
        ClientColors.onJourneyRed,
      ),
      PaymentStatus.refunded => (
        ClientColors.journeySlateLight,
        ClientColors.onJourneySlate,
      ),
      PaymentStatus.cancelled => (
        ClientColors.journeySlateLight,
        ClientColors.onJourneySlate,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: ClientTypography.labelSmall(context).copyWith(color: fg),
      ),
    );
  }
}
