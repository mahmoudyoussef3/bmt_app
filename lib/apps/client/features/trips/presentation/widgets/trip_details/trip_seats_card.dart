import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
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
          const SizedBox(height: 16),
          TripSeatCabin(seats: trip.seatMap, vehicleType: trip.vehicleType),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullScreenSeatMapScreen(
                    seats: trip.seatMap,
                    vehicleName: vehicleNameFor(context, trip),
                    vehicleType: trip.vehicleType,
                  ),
                ),
              ),
              icon: const Icon(Icons.fullscreen_rounded, size: 20),
              label: Text(context.l10n.trips_viewFullSeatMap),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: ClientColors.primary,
                side: BorderSide(color: ClientColors.borderFor(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ] else if (mySeats.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            context.l10n.trips_seatPendingAssignment,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ],
      ],
    );
  }
}
