import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/payment_row.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_status_mapping.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

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
                  _paymentNote(context, trip.paymentStatus),
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
              ),
              const SizedBox(width: 10),
              TripInlineBadge(
                label: paymentLabelFor(context, trip.paymentStatus),
                color: color,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PaymentRow(label: context.l10n.payments_ticketFare, value: trip.fare),
        const SizedBox(height: 8),
        PaymentRow(label: context.l10n.payments_serviceFee, value: '0'),
        const SizedBox(height: 8),
        PaymentRow(label: context.l10n.trips_discountLabel, value: '0'),
        Divider(height: 26, color: ClientColors.borderFor(context)),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.payments_total,
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

  String _paymentNote(BuildContext context, PaymentStatus status) {
    return switch (status) {
      PaymentStatus.paid => context.l10n.trips_paymentNotePaid,
      PaymentStatus.pending => context.l10n.trips_paymentNotePending,
      PaymentStatus.underReview => context.l10n.trips_paymentNoteUnderReview,
      PaymentStatus.refunded => context.l10n.trips_paymentNoteRefunded,
      PaymentStatus.failed => context.l10n.trips_paymentNoteFailed,
      PaymentStatus.cancelled => context.l10n.trips_paymentNoteCancelled,
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
