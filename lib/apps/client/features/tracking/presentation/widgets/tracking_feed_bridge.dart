import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/live_tracking_bloc.dart';
import '../bloc/live_tracking_event.dart';
import '../bloc/live_tracking_state.dart';
import '../cubit/tracking_cubit.dart';
import '../cubit/tracking_state.dart';

/// Introduces the trip document and the live feed to each other.
///
/// Both surfaces that track a vehicle — the full tracking screen and the live
/// card in the trips list — need the same two wires, and they are deliberately
/// one-directional in each direction:
///
/// * the trip document tells the feed **which trip to follow**, because the route
///   progress engine is built out of the trip's stops and the captain's confirmed
///   arrivals;
/// * the feed tells the trip document the one thing a position can prove about it
///   — that the bus is moving.
///
/// Neither reads the other's state. Keeping the wiring in a widget rather than
/// inside either holder is what stops it becoming a two-way coupling, which is
/// the thing that would make both of them untestable.
class TrackingFeedBridge extends StatelessWidget {
  const TrackingFeedBridge({super.key, required this.child});

  final Widget child;

  /// Only the parts of the trip the feed is built from.
  ///
  /// Without this the feed would be re-requested on every unrelated cubit emit —
  /// a refresh flag, a boarding spinner — and each one would recompute the
  /// engine's derived state for nothing.
  static bool feedInputChanged(TrackingState previous, TrackingState current) {
    if (current is! TrackingLoaded) return current is TrackingEmpty;
    if (previous is! TrackingLoaded) return true;
    final a = previous.data;
    final b = current.data;
    return a.tripId != b.tripId ||
        a.tripState != b.tripState ||
        a.stops.length != b.stops.length ||
        a.arrivalEventCount != b.arrivalEventCount ||
        a.rider.canTrackVehicle != b.rider.canTrackVehicle;
  }

  static void syncFeed(BuildContext context, TrackingState state) {
    final bloc = context.read<LiveTrackingBloc>();
    if (state is! TrackingLoaded) {
      bloc.add(const TrackingStopped());
      return;
    }
    // A trip that ends while being watched, and one that was already over when
    // the screen opened, are different occurrences arriving by different routes.
    // Both must release the feed; `TrackingRequested` covers the cold-load case.
    if (state.data.tripState.isFinished) {
      bloc.add(const TrackingFinished());
      return;
    }
    bloc.add(TrackingRequested(state.data));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TrackingCubit, TrackingState>(
          listenWhen: feedInputChanged,
          listener: syncFeed,
        ),
        BlocListener<LiveTrackingBloc, LiveTrackingState>(
          listenWhen: (previous, current) =>
              previous is! LiveTrackingActive && current is LiveTrackingActive,
          listener: (context, _) =>
              context.read<TrackingCubit>().noteVehicleMoving(),
        ),
      ],
      child: child,
    );
  }
}
