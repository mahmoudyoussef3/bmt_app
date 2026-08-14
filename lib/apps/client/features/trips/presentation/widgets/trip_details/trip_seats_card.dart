import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/screens/full_screen_seat_map_screen.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seat_cabin.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seat_summary.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_identity_labels.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The passenger's reserved seat(s) rendered on the vehicle's real seat map —
/// the same live layout the passenger saw while booking, not a mock preview.
class TripSeatsCard extends StatelessWidget {
  const TripSeatsCard({super.key, required this.trip});

  final TripData trip;

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenSeatMapScreen(
          seats: trip.seatMap,
          vehicleName: vehicleNameFor(context, trip),
          vehicleType: trip.vehicleType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mySeats = trip.mySeatLabels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TripSeatSummary(
          mySeatLabels: mySeats,
          availableSeats: trip.availableSeatCount,
          totalSeats: trip.vehicleCapacity,
        ),
        if (trip.hasSeatMap) ...[
          const SizedBox(height: 14),
          // The cabin is the tap target; the link below it is the affordance
          // that says so. A full-width filled button for a second view of the
          // same map outweighed the map itself.
          InkWell(
            onTap: () => _openFullScreen(context),
            borderRadius: BorderRadius.circular(ClientRadius.md),
            child: TripSeatCabin(
              seats: trip.seatMap,
              vehicleType: trip.vehicleType,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () => _openFullScreen(context),
              icon: const Icon(Icons.open_in_full_rounded, size: 16),
              label: Text(context.l10n.trips_viewFullSeatMap),
              style: TextButton.styleFrom(
                foregroundColor: ClientColors.primaryFor(context),
                textStyle: ClientTypography.labelLarge(context),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ClientRadius.sm),
                ),
              ),
            ),
          ),
        ] else if (mySeats.isEmpty) ...[
          const SizedBox(height: 12),
          const _SeatPendingNotice(),
        ],
      ],
    );
  }
}

/// Shown when neither a live layout nor a booked seat label exists yet — the
/// dashboard has not assigned this booking a seat.
class _SeatPendingNotice extends StatelessWidget {
  const _SeatPendingNotice();

  @override
  Widget build(BuildContext context) {
    final ink = ClientColors.onJourneyAmberFor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ClientColors.journeyAmberLightFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.sm),
        border: Border.all(
          color: ClientColors.journeyAmberFor(context).withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: ink, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.trips_seatPendingAssignment,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
