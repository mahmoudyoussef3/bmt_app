import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trips_state.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_list/my_trips_body.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// My Trips hub with filter tabs for upcoming, active, completed, cancelled.
class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({
    super.key,
    required this.onOpenRoute,
    this.showBackButton = false,
  });

  final void Function(String route, [Object? arguments]) onOpenRoute;

  /// True when this screen is pushed as a standalone destination (e.g. from
  /// the Profile hub) rather than hosted as the Trips tab, which already sits
  /// at the root of the bottom navigation and needs no way back.
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: showBackButton
            ? ClientAppBar(
                title: context.l10n.nav_trips,
                backgroundColor: Colors.transparent,
              )
            : null,
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
