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
    final color = _paymentColor(trip.paymentStatus);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                  trip.paymentLabel,
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(color: color),
                ),
              ),
              TripInlineBadge(label: trip.paymentLabel, color: color),
            ],
          ),
          const SizedBox(height: 16),
          PaymentRow(label: 'Trip fare', value: trip.fare),
          const SizedBox(height: 8),
          const PaymentRow(label: 'Service fee', value: '0'),
          const SizedBox(height: 8),
          const PaymentRow(label: 'Discount', value: '0'),
          Divider(height: 24, color: ClientColors.borderFor(context)),
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
                ).copyWith(fontSize: 20, color: ClientColors.primary),
              ),
            ],
          ),
      ],
    );
  }

  Color _paymentColor(PaymentStatus status) {
    return switch (status) {
      PaymentStatus.paid => ClientColors.journeyGreen,
      PaymentStatus.pending => ClientColors.journeyAmber,
      PaymentStatus.underReview => ClientColors.journeyAmber,
      PaymentStatus.refunded => ClientColors.primary,
      PaymentStatus.failed => ClientColors.journeyRed,
    };
  }
}
