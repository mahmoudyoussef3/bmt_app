import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

import '../../../domain/entities/tracking_rider.dart';
import '../../formatters/tracking_labels.dart';
import 'tracking_card_parts.dart';

/// The rider's own leg: their seat, where they board, where they get off, and
/// whether the captain has actually checked them in.
///
/// All four come from this passenger's `trip_passengers` row. Where the
/// manifest is not readable the card leaves the line out rather than inventing
/// a seat number.
class TrackingBookingCard extends StatelessWidget {
  const TrackingBookingCard({
    super.key,
    required this.rider,
    required this.labels,
  });

  final TrackingRider rider;
  final TrackingLabels labels;

  @override
  Widget build(BuildContext context) {
    final l10n = labels.l10n;
    final boarding = rider.boardingName;
    final dropoff = rider.dropoffName;

    return ClientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.tracking_yourBooking,
                  style: ClientTypography.labelMedium(context),
                ),
              ),
              if (rider.hasSeat)
                TrackingChip(
                  label: l10n.tracking_seat(rider.seatLabel!),
                  color: ClientColors.primaryFor(context),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (boarding != null)
            TrackingLegRow(
              icon: Icons.trip_origin_rounded,
              label: l10n.tracking_boardAt,
              value: boarding,
            ),
          if (boarding != null && dropoff != null) const SizedBox(height: 10),
          if (dropoff != null)
            TrackingLegRow(
              icon: Icons.place_rounded,
              label: l10n.tracking_alightAt,
              value: dropoff,
              color: ClientColors.journeyRedFor(context),
            ),
          if (rider.status != null) ...[
            const SizedBox(height: 12),
            TrackingChip(
              label: rider.hasBoarded
                  ? l10n.tracking_boarded
                  : l10n.tracking_notBoarded,
              color: rider.hasBoarded
                  ? ClientColors.journeyCyanFor(context)
                  : ClientColors.journeyAmberFor(context),
              icon: rider.hasBoarded
                  ? Icons.check_circle_rounded
                  : Icons.schedule_rounded,
            ),
          ],
        ],
      ),
    );
  }
}
