import 'package:equatable/equatable.dart';

import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';

import '../../domain/entities/tracking_trip.dart';

/// What the tracking widgets need to know, and nothing else.
///
/// The trip document — captain, vehicle, seat, stops, booking — stays with
/// `TrackingCubit`, which owns it. Duplicating it here would give the screen two
/// answers to the same question. What lives here is only what a *position*
/// changes: where the vehicle is, when that was, whether it can still be
/// believed, whether the link is healthy, and the route progress derived from it.
sealed class LiveTrackingState extends Equatable {
  const LiveTrackingState({this.progress});

  /// Route progress, ETAs and per-stop status, from the shared
  /// `RouteProgressEngine`.
  ///
  /// Present on every state that can have it — including before the first fix,
  /// because the captain's confirmed station arrivals seed real progress with no
  /// GPS at all, and including after the rider boards, because the route and the
  /// stops are still their journey even once the marker goes.
  final RouteProgressSnapshot? progress;

  @override
  List<Object?> get props => [progress];
}

/// Nothing is being tracked: before the first request, and after a clean stop.
class LiveTrackingIdle extends LiveTrackingState {
  const LiveTrackingIdle();
}

/// The feed is opening. There may already be progress to draw from the captain's
/// confirmed arrivals; there is not yet a position.
class LiveTrackingConnecting extends LiveTrackingState {
  const LiveTrackingConnecting({super.progress});
}

/// The working state.
class LiveTrackingActive extends LiveTrackingState {
  const LiveTrackingActive({
    required this.fix,
    required this.receivedAt,
    required this.freshness,
    required this.link,
    super.progress,
  });

  /// The latest accepted position.
  final TrackingPoint fix;

  /// When it landed **here**, not when the device says it was recorded.
  ///
  /// Freshness is measured against this deliberately: a captain's device with a
  /// skewed clock could otherwise stamp a fix into the future and keep a dead
  /// feed looking alive forever.
  final DateTime receivedAt;

  final TrackingFreshness freshness;
  final TrackingLink link;

  /// Live means fresh **and** connected. A rider deciding whether to trust the
  /// dot cares about the conjunction, not either half.
  bool get isLive => freshness == TrackingFreshness.live && link.isConnected;

  LiveTrackingActive copyWith({
    TrackingPoint? fix,
    DateTime? receivedAt,
    TrackingFreshness? freshness,
    TrackingLink? link,
    RouteProgressSnapshot? progress,
  }) {
    return LiveTrackingActive(
      fix: fix ?? this.fix,
      receivedAt: receivedAt ?? this.receivedAt,
      freshness: freshness ?? this.freshness,
      link: link ?? this.link,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [
    fix.latitude,
    fix.longitude,
    fix.recordedAt,
    receivedAt,
    freshness,
    link,
    progress,
  ];
}

/// This rider may not watch the vehicle — they have boarded, so the waiting-stage
/// feed is not theirs any more. Not an error, and not an empty screen: the route
/// and their stops remain.
class LiveTrackingUnavailable extends LiveTrackingState {
  const LiveTrackingUnavailable({super.progress});
}

/// The trip is over. The feed is released; the last known progress is kept so the
/// completed journey still renders.
class LiveTrackingFinished extends LiveTrackingState {
  const LiveTrackingFinished({super.progress});
}

/// The feed could not be established or fell over.
class LiveTrackingFailure extends LiveTrackingState {
  const LiveTrackingFailure(this.message, {this.canRetry = true, super.progress});

  final String message;
  final bool canRetry;

  @override
  List<Object?> get props => [message, canRetry, progress];
}
