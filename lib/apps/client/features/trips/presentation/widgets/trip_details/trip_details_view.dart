import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_attention_banner.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_cancellation_flow.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_actions_bar.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_brand_app_bar.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_detail_sections.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_hero_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_live_tracking_card.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review_flow.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

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


  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<TripsCubit>();
    final reason = await showTripCancellationFlow(
      context,
      tripReference: trip.reference,
    );
    if (reason == null) return;
    await cubit.cancelTrip(trip, reason);
  }


  Future<void> _rateTrip(BuildContext context) async {
    final cubit = context.read<TripsCubit>();
    await showTripReviewFlow(context, trip: trip.reviewable);
    await cubit.refreshSelectedTrip(trip.id);
  }

  @override
  Widget build(BuildContext context) {
    final canCancel = trip.canBeCancelled;
    final canReview = trip.canBeReviewed;
    final canTrack = trip.canBeTracked;

    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      appBar: TripBrandAppBar(
        actions: [
          
          if (onRefresh != null)
            IconButton(
              tooltip: context.l10n.tracking_refresh,
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
              
              TripAttentionBanner(trip: trip),
              if (trip.attention != TripAttention.none)
                const SizedBox(height: 14),
              TripHeroCard(trip: trip),
              const SizedBox(height: 14),
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
        onReview: () => _rateTrip(context),
      ),
    );
  }
}
