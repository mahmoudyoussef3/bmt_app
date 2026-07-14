import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/summary/summary_fare_row.dart';

/// What the rider pays and why. A package is a flat price for its whole ride
/// bundle, so we show the real per-ride cost it works out to rather than
/// inventing a subtotal the rider is never charged.
class SummaryFareCard extends StatelessWidget {
  const SummaryFareCard({super.key, required this.session});

  final BookingWizardSession session;

  @override
  Widget build(BuildContext context) {
    final plan = session.selectedPackage;
    final rides = plan?.rideCount ?? 1;
    final total = session.totalPrice;
    final singleFare = session.tripPrice;
    final perRide = rides > 0 ? total / rides : total;
    final saved = (singleFare * rides) - total;
    final start = session.packageStartDate;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fare breakdown',
            style: ClientTypography.headingSmall(context),
          ),
          const SizedBox(height: 8),
          if (plan != null)
            SummaryFareRow(
              label: plan.displayName,
              note: start == null
                  ? '$rides rides'
                  : '$rides rides · starts ${formatCalendarDay(context, start)}',
              value: _egp(total),
            ),
          if (rides > 1)
            SummaryFareRow(
              label: 'Works out to',
              note: 'per ride',
              value: _egp(perRide),
            ),
          if (saved >= 1)
            SummaryFareRow(
              label: 'You save',
              note: 'vs. $rides single tickets',
              value: '− ${_egp(saved)}',
              color: ClientColors.journeyGreen,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 1,
              color: ClientColors.borderFor(context),
            ),
          ),
          SummaryFareRow(
            label: 'Total due',
            value: _egp(total),
            emphasis: true,
          ),
        ],
      ),
    );
  }

  String _egp(double amount) => 'EGP ${amount.toStringAsFixed(0)}';
}
