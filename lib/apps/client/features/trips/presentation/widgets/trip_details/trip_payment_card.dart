import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/payment_row.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';

/// The fare breakdown and payment status for this trip.
class TripPaymentCard extends StatelessWidget {
  const TripPaymentCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final color = _paymentColor(context, trip.paymentStatus);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(_paymentIcon(trip.paymentStatus), size: 20, color: color),
              const SizedBox(width: 10),
              // The status word itself is the badge — printing it as a heading
              // too, as this card used to, said the same thing twice.
              Expanded(
                child: Text(
                  _paymentNote(trip.paymentStatus),
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
              ),
              const SizedBox(width: 10),
              TripInlineBadge(label: trip.paymentLabel, color: color),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PaymentRow(label: 'Trip fare', value: trip.fare),
        const SizedBox(height: 8),
        const PaymentRow(label: 'Service fee', value: '0'),
        const SizedBox(height: 8),
        const PaymentRow(label: 'Discount', value: '0'),
        Divider(height: 26, color: ClientColors.borderFor(context)),
        Row(
          children: [
            Expanded(
              child: Text(
                'Total',
                style: ClientTypography.headingSmall(
                  context,
                ).copyWith(color: ClientColors.textPrimaryFor(context)),
              ),
            ),
            Text(
              trip.fare,
              style: ClientTypography.priceHero(
                context,
              ).copyWith(fontSize: 22, color: ClientColors.primaryFor(context)),
            ),
          ],
        ),
      ],
    );
  }

  String _paymentNote(PaymentStatus status) {
    return switch (status) {
      PaymentStatus.paid => 'Your payment is confirmed.',
      PaymentStatus.pending => 'Waiting for your payment.',
      PaymentStatus.underReview => 'Our team is reviewing your payment.',
      PaymentStatus.refunded => 'This fare was refunded to you.',
      PaymentStatus.failed => 'The payment did not go through.',
      PaymentStatus.cancelled => 'This booking was cancelled.',
    };
  }

  IconData _paymentIcon(PaymentStatus status) {
    return switch (status) {
      PaymentStatus.paid => Icons.verified_rounded,
      PaymentStatus.pending => Icons.hourglass_top_rounded,
      PaymentStatus.underReview => Icons.pending_actions_rounded,
      PaymentStatus.refunded => Icons.replay_rounded,
      PaymentStatus.failed => Icons.error_rounded,
      PaymentStatus.cancelled => Icons.cancel_rounded,
    };
  }

  Color _paymentColor(BuildContext context, PaymentStatus status) {
    return switch (status) {
      PaymentStatus.paid => ClientColors.journeyCyan,
      PaymentStatus.pending => ClientColors.journeyAmber,
      PaymentStatus.underReview => ClientColors.journeyAmber,
      PaymentStatus.refunded => ClientColors.primary,
      PaymentStatus.failed => ClientColors.journeyRed,
      PaymentStatus.cancelled => ClientColors.textSecondaryFor(context),
    };
  }
}
