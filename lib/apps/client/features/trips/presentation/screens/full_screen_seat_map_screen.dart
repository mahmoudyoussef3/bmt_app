import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_seat.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_seat_cabin.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// A focused, full-screen view of the trip's real seat layout, so the
/// passenger can inspect exactly where their seat sits in the cabin.
class FullScreenSeatMapScreen extends StatelessWidget {
  const FullScreenSeatMapScreen({
    super.key,
    required this.seats,
    required this.vehicleName,
  });

  final List<TripSeat> seats;
  final String vehicleName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      appBar: AppBar(
        backgroundColor: ClientColors.surfaceFor(context),
        title: Text(
          vehicleName.trim().isEmpty
              ? context.l10n.trips_seatMapTitle
              : context.l10n.trips_seatMapTitleWithVehicle(vehicleName),
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: ClientColors.textPrimaryFor(context)),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.maxContentWidth(
              MediaQuery.sizeOf(context).width,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: TripSeatCabin(seats: seats, seatSize: 52),
          ),
        ),
      ),
    );
  }
}
