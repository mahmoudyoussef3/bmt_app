import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

import '../bloc/live_tracking_bloc.dart';
import '../bloc/live_tracking_state.dart';

/// Rebuilds its child only when route progress actually changes.
///
/// This is the rebuild boundary the whole live feed is designed around. A moving
/// vehicle emits a new state every few seconds, and almost nothing on the screen
/// is about the vehicle: the booking card, the seat, the crew, the boarding
/// button and the sheet chrome are all facts about the *trip*, and repainting
/// them because a bus travelled twelve metres is wasted frames on a phone that is
/// also holding a map open.
///
/// A `BlocSelector` on the snapshot gets this for free in both directions. The
/// snapshot has no value equality, so a genuinely new one always rebuilds; and
/// when the bloc emits a state that carries the *same* snapshot object — a link
/// flapping, freshness ticking over — the selector sees an identical reference and
/// skips the rebuild entirely.
class LiveProgressBuilder extends StatelessWidget {
  const LiveProgressBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, RouteProgressSnapshot? progress)
  builder;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LiveTrackingBloc, LiveTrackingState,
        RouteProgressSnapshot?>(
      selector: (state) => state.progress,
      builder: builder,
    );
  }
}
