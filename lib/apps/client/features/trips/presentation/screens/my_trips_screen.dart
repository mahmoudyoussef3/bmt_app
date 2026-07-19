import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_list/my_trips_body.dart';

/// My Trips hub with filter tabs for upcoming, active, completed, cancelled.
class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key, required this.onOpenRoute});

  final void Function(String route, [Object? arguments]) onOpenRoute;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: BlocBuilder<TripsCubit, TripsState>(
          builder: (context, state) {
            final loaded = state is TripsLoaded ? state : null;
            return MyTripsBody(
              state: state,
              filter: loaded?.filter ?? TripFilter.upcoming,
              trips: loaded?.filteredTrips ?? const [],
              counts: loaded?.counts ?? const {},
              onOpenRoute: onOpenRoute,
            );
          },
        ),
      ),
    );
  }
}
