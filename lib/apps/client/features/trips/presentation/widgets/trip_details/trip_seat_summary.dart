import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/boarding_pass_parts.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The headline for the Seats section: the passenger's own seat(s) on the
/// leading side, live cabin availability on the trailing side.
///
/// The seat is set in the boarding-pass field style used for the reference and
/// the seat on the ticket above, so the same fact reads the same twice on one
/// screen — and it sits flat on the section, which is already a card.
class TripSeatSummary extends StatelessWidget {
  const TripSeatSummary({
    super.key,
    required this.mySeatLabels,
    required this.availableSeats,
    required this.totalSeats,
  });

  final List<String> mySeatLabels;
  final int availableSeats;
  final int totalSeats;

  @override
  Widget build(BuildContext context) {
    final hasSeats = mySeatLabels.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: BoardingField(
            label: hasSeats
                ? (mySeatLabels.length == 1
                      ? context.l10n.trips_seatLegendYours
                      : context.l10n.trips_yourSeatsPlural)
                : context.l10n.trips_seatPending,
            value: hasSeats
                ? mySeatLabels.join(' · ')
                : context.l10n.trips_awaitingConfirmation,
            emphasis: hasSeats,
          ),
        ),
        if (totalSeats > 0) ...[
          const SizedBox(width: 12),
          _CabinAvailability(
            availableSeats: availableSeats,
            totalSeats: totalSeats,
          ),
        ],
      ],
    );
  }
}

/// How much of the cabin is still open, as a figure rather than a panel.
class _CabinAvailability extends StatelessWidget {
  const _CabinAvailability({
    required this.availableSeats,
    required this.totalSeats,
  });

  final int availableSeats;
  final int totalSeats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_seat_outlined,
              size: 14,
              color: ClientColors.textTertiaryFor(context),
            ),
            const SizedBox(width: 6),
            Text(
              context.l10n.trips_seatsAvailableOfTotal(
                availableSeats,
                totalSeats,
              ),
              style: ClientTypography.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w800,
                color: ClientColors.textPrimaryFor(context),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Text(
          context.l10n.trips_seatsFreeLabel,
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textTertiaryFor(context)),
        ),
      ],
    );
  }
}
