import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/reviewable_trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trip_review_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trip_review_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_review/trip_review_rating_card.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The office / driver / vehicle / route star cards a passenger fills in.
///
/// The office is rated first and explicitly: it is the marketplace entity the
/// passenger chose, and its reputation is never inferred from the other three.
class TripReviewRatings extends StatelessWidget {
  const TripReviewRatings({super.key, required this.trip, required this.state});

  final ReviewableTrip trip;
  final TripReviewEditing state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripReviewCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TripReviewRatingCard(
          title: context.l10n.trips_ratingOffice,
          subtitle: trip.officeName,
          value: state.draft.officeRating,
          onChanged: cubit.rateOffice,
        ),
        const SizedBox(height: 16),
        TripReviewRatingCard(
          title: context.l10n.trips_ratingDriver,
          subtitle: trip.driverName,
          value: state.draft.driverRating,
          onChanged: cubit.rateDriver,
        ),
        const SizedBox(height: 16),
        TripReviewRatingCard(
          title: context.l10n.trips_ratingVehicle,
          subtitle: trip.vehicleName,
          value: state.draft.vehicleRating,
          onChanged: cubit.rateVehicle,
        ),
        const SizedBox(height: 16),
        TripReviewRatingCard(
          title: context.l10n.trips_ratingRoute,
          subtitle: trip.routeLine,
          value: state.draft.routeRating,
          onChanged: cubit.rateRoute,
        ),
      ],
    );
  }
}
