import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/ticket_tear_line.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/boarding_pass_parts.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_inline_badge.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_schedule_labels.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_soft_icon.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// A QR-free boarding pass for upcoming/in-progress trips — the reference, the
/// seat, and where to be, in the order a passenger needs them at the door.
class TripBoardingCard extends StatelessWidget {
  const TripBoardingCard({super.key, required this.trip});

  final TripData trip;

  static const double _padding = 20;

  @override
  Widget build(BuildContext context) {
    final seats = trip.mySeatLabels;
    final onBoard = trip.status == TripStatus.inProgress;

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TripSoftIcon(
                icon: Icons.confirmation_number_rounded,
                color: ClientColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.trips_boardingPassTitle,
                  style: ClientTypography.headingSmall(context),
                ),
              ),
              TripInlineBadge(
                label: onBoard
                    ? context.l10n.trips_boardingOnBoard
                    : context.l10n.trips_boardingReady,
                color: ClientColors.journeyCyan,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: BoardingField(
                  label: context.l10n.trips_bookingRefLabel,
                  value: trip.reference,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: BoardingField(
                  label: seats.length > 1
                      ? context.l10n.common_seats
                      : context.l10n.trips_factSeat,
                  value: seats.isEmpty ? '—' : seats.join(', '),
                  emphasis: true,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: TicketTearLine(inset: _padding),
          ),
          BoardingStubLine(
            icon: Icons.location_on_rounded,
            label: context.l10n.tracking_boardAt,
            value: trip.pickup,
          ),
          const SizedBox(height: 10),
          BoardingStubLine(
            icon: Icons.schedule_rounded,
            label: context.l10n.trips_factDeparts,
            value: tripDepartureLabel(context, trip),
          ),
          const SizedBox(height: 14),
          Text(
            onBoard
                ? context.l10n.trips_boardingOnBoardNote
                : context.l10n.trips_boardingReadyNote,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
        ],
      ),
    );
  }
}
