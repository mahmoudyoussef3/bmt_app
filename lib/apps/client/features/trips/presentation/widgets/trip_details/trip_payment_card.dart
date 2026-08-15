import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_soft_icon.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_status_mapping.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// What this trip cost, in one card: the amount, and the state that amount is
/// in. There is no line-item breakdown any more — a ticket fare with a zero
/// service fee and a zero discount above it was three rows spent to restate the
/// one number underneath them.
class TripPaymentCard extends StatelessWidget {
  const TripPaymentCard({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final color = _paymentColor(context, trip.paymentStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ClientColors.borderFor(context)),
        boxShadow: [
          BoxShadow(
            color: ClientColors.shadowFor(context).withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          TripSoftIcon(icon: Icons.payments_rounded, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _totalLabel(context, trip.paymentStatus),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClientTypography.bodySmall(context).copyWith(
                          color: ClientColors.textTertiaryFor(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TripInlineBadge(
                      label: paymentLabelFor(context, trip.paymentStatus),
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  trip.fare,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.priceHero(context).copyWith(
                    // The amount itself is never tinted by the payment state.
                    // Money read in a warning colour looks like a problem with
                    // the money; the state belongs on the pill beside it.
                    color: ClientColors.textPrimaryFor(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Money that has not actually left the passenger's hands is never labelled
  /// as paid — a pending or failed booking still owes this amount.
  String _totalLabel(BuildContext context, PaymentStatus status) {
    return switch (status) {
      PaymentStatus.paid ||
      PaymentStatus.refunded => context.l10n.trips_totalPaid,
      PaymentStatus.pending ||
      PaymentStatus.underReview ||
      PaymentStatus.failed ||
      PaymentStatus.cancelled => context.l10n.trips_totalDue,
    };
  }

  /// Amber is deliberately absent. A booking waiting on approval is not a
  /// warning — it is simply not settled yet — so waiting states read in the
  /// neutral slate, and only a genuinely failed payment gets an alarm colour.
  Color _paymentColor(BuildContext context, PaymentStatus status) {
    return switch (status) {
      PaymentStatus.paid => ClientColors.journeyCyanFor(context),
      PaymentStatus.pending => ClientColors.journeySlateFor(context),
      PaymentStatus.underReview => ClientColors.journeySlateFor(context),
      PaymentStatus.refunded => ClientColors.primaryFor(context),
      PaymentStatus.failed => ClientColors.journeyRedFor(context),
      PaymentStatus.cancelled => ClientColors.textSecondaryFor(context),
    };
  }
}
