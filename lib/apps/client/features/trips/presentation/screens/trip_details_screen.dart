import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_cancellation_notice.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_details_view.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_empty_view.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_error_view.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_loading_view.dart';

/// Premium trip details screen with a branded boarding pass, route timeline,
/// driver actions, vehicle info, a live seat map, payment summary, and the
/// cancel/track/review flows — with loading, empty, and error states.
class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({super.key, this.tripId});

  final String? tripId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripsCubit, TripsState>(
      listener: (context, state) {
        if (state is TripsLoaded) showTripCancellationNotice(context, state);
      },
      builder: (context, state) {
        return switch (state) {
          TripsLoading() => const TripLoadingView(),
          TripsError(:final message) => TripErrorView(
            message: message,
            onRetry: () => context.read<TripsCubit>().loadTripDetails(tripId),
          ),
          TripsLoaded(:final selectedTrip?, :final cancelInFlight) =>
            TripDetailsView(
              trip: selectedTrip,
              cancelInFlight: cancelInFlight,
              onRefresh: () =>
                  context.read<TripsCubit>().loadTripDetails(tripId),
            ),
          TripsLoaded() => const TripEmptyView(),
        };
      },
    );
  }
}
