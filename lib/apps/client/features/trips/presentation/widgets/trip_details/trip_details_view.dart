import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_cancellation_flow.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_actions_bar.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_boarding_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_brand_app_bar.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_detail_sections.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_hero_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_live_tracking_card.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// The fully-loaded Trip Details screen body.
class TripDetailsView extends StatelessWidget {
  const TripDetailsView({
    super.key,
    required this.trip,
    this.onRefresh,
    this.cancelInFlight = false,
  });

  final TripData trip;
  final VoidCallback? onRefresh;
  final bool cancelInFlight;

  /// Asks for a reason, then actually cancels — releasing the seat and pulling
  /// the payment out of the dashboard's review queue.
  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<TripsCubit>();
    final reason = await showTripCancellationFlow(
      context,
      tripReference: trip.reference,
    );
    if (reason == null) return;
    await cubit.cancelTrip(trip, reason);
  }

  @override
  Widget build(BuildContext context) {
    // Cancelling is only offered while the dashboard has not approved the
    // payment yet; an approved seat is paid for and final.
    final canCancel = trip.canBeCancelled;
    final canReview = trip.status == TripStatus.completed;
    // The vehicle must stay untrackable until this booking's own payment is
    // approved — a trip can be in progress for other passengers while this
    // client's payment is still pending review.
    final canTrack =
        trip.status == TripStatus.inProgress &&
        trip.paymentStatus == PaymentStatus.paid;
    final showBoarding = canCancel || canTrack;

    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      appBar: TripBrandAppBar(
        actions: [
          // Cancelling lives in the bottom bar only. Mirroring it up here gave
          // the screen two destructive buttons, one of them a stray tap away
          // from the back arrow.
          if (onRefresh != null)
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: onRefresh,
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              TripHeroCard(trip: trip),
              const SizedBox(height: 14),
              if (showBoarding) ...[
                TripBoardingCard(trip: trip),
                const SizedBox(height: 14),
              ],
              if (canTrack) ...[
                TripLiveTrackingCard(trip: trip),
                const SizedBox(height: 14),
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
        cancelInFlight: cancelInFlight,
        onCancel: () => _confirmCancel(context),
      ),
    );
  }
}
