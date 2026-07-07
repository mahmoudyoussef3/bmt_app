import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_cancellation_flow.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_actions_bar.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_detail_sections.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_hero_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_ticket_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_live_tracking_card.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// The fully-loaded Trip Details screen body.
class TripDetailsView extends StatelessWidget {
  const TripDetailsView({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final canCancel = trip.status == TripStatus.upcoming;
    final canReview = trip.status == TripStatus.completed;
    final canTrack = trip.status == TripStatus.inProgress;
    final showQr =
        trip.status == TripStatus.upcoming ||
        trip.status == TripStatus.inProgress;

    return Scaffold(
      extendBody: true,
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      appBar: AppBar(
        backgroundColor: ClientColors.surfaceFor(context),
        title: Text(
          'Trip Details',
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: ClientColors.textPrimaryFor(context)),
        ),
        centerTitle: false,
        actions: [
          if (canCancel)
            TextButton.icon(
              onPressed: () => showTripCancellationFlow(
                context,
                tripReference: trip.reference,
              ),
              icon: const Icon(
                Icons.close_rounded,
                color: ClientColors.journeyRed,
                size: 18,
              ),
              label: const Text(
                'Cancel',
                style: TextStyle(
                  color: ClientColors.journeyRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.maxContentWidth(
              MediaQuery.sizeOf(context).width,
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 128),
            children: [
              TripHeroCard(trip: trip),
              const SizedBox(height: 16),
              if (showQr) ...[
                TripTicketCard(trip: trip),
                const SizedBox(height: 16),
              ],
              if (canTrack) ...[
                TripLiveTrackingCard(trip: trip),
                const SizedBox(height: 16),
              ],
              TripDetailSections(trip: trip),
            ],
          ),
        ),
      ),
      bottomNavigationBar: TripActionsBar(
        trip: trip,
        canCancel: canCancel,
        canReview: canReview,
        canTrack: canTrack,
      ),
    );
  }
}
