import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/live_ops_snapshot.dart';
import '../bloc/fleet_tracking_bloc.dart';
import '../bloc/fleet_tracking_event.dart';
import '../cubit/live_ops_cubit.dart';
import '../cubit/live_ops_state.dart';

/// Wires the roster [LiveOpsCubit] to the position [FleetTrackingBloc].
///
/// A widget, not logic inside either state holder — the same choice the client's
/// `TrackingFeedBridge` makes, for the same reason. The wiring is strictly
/// one-directional: the roster tells the feed which trips are on the road (and
/// hands over their backfilled positions to seed the map); the feed tells the
/// roster nothing at all. Neither reads the other's state.
///
/// Putting this in a widget is what stops it becoming a two-way coupling, which
/// is what would make both holders untestable — and it is why a bus moving cannot
/// trigger a roster refetch.
class FleetTrackingScope extends StatelessWidget {
  const FleetTrackingScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LiveOpsCubit, LiveOpsState>(
      // Only a changed roster is news for the feed. A snapshot that arrived
      // because an incident was acknowledged must not re-seed positions.
      listenWhen: (previous, current) =>
          current is LiveOpsLoaded &&
          (previous is! LiveOpsLoaded ||
              !_sameRoster(
                previous.snapshot.activeTrips,
                current.snapshot.activeTrips,
              )),
      listener: (context, state) {
        if (state is! LiveOpsLoaded) return;
        context.read<FleetTrackingBloc>().add(
          FleetTripsChanged(state.snapshot.activeTrips),
        );
      },
      child: child,
    );
  }

  static bool _sameRoster(List<LiveTrip> a, List<LiveTrip> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}
