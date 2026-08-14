import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/dashed_divider.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/payment_row.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_status_mapping.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The fare breakdown and payment status for this trip, read as a receipt:
/// where the money stands, what it is made of, then what it comes to.
class TripPaymentCard extends StatelessWidget {
  const TripPaymentCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final color = _paymentColor(context, trip.paymentStatus);

    return Column(
      children: [
        _PaymentStatusStrip(trip: trip, color: color),
        const SizedBox(height: 16),
        PaymentRow(label: context.l10n.payments_ticketFare, value: trip.fare),
        const SizedBox(height: 8),
        PaymentRow(
          label: context.l10n.payments_serviceFee,
          value: '0',
          muted: true,
        ),
        const SizedBox(height: 8),
        PaymentRow(
          label: context.l10n.trips_discountLabel,
          value: '0',
          muted: true,
        ),
        const SizedBox(height: 12),
        DashedDivider(color: ClientColors.borderFor(context)),
        const SizedBox(height: 12),
        _PaymentTotal(fare: trip.fare, color: color),
      ],
    );
  }

  Color _paymentColor(BuildContext context, PaymentStatus status) {
    return switch (status) {
      PaymentStatus.paid => ClientColors.journeyCyanFor(context),
      PaymentStatus.pending => ClientColors.journeyAmberFor(context),
      PaymentStatus.underReview => ClientColors.journeyAmberFor(context),
      PaymentStatus.refunded => ClientColors.primaryFor(context),
      PaymentStatus.failed => ClientColors.journeyRedFor(context),
      PaymentStatus.cancelled => ClientColors.textSecondaryFor(context),
    };
  }
}

/// Where the money stands, in one line: state icon, what that means, and the
/// state itself as a pill.
class _PaymentStatusStrip extends StatelessWidget {
  const _PaymentStatusStrip({required this.trip, required this.color});

  final TripData trip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(_paymentIcon(trip.paymentStatus), size: 18, color: color),
          const SizedBox(width: 10),
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
}

/// The bottom line, tinted by the payment state so the amount and its status
/// are never read apart.
class _PaymentTotal extends StatelessWidget {
  const _PaymentTotal({required this.fare, required this.color});

  final String fare;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.payments_total,
              style: ClientTypography.headingSmall(
                context,
              ).copyWith(color: ClientColors.textPrimaryFor(context)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            fare,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.priceMedium(context).copyWith(
              fontSize: 22,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
