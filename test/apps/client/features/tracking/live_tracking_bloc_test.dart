import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/bloc/live_tracking_bloc.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/bloc/live_tracking_event.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/bloc/live_tracking_state.dart';
import 'package:bmt_app/core/tracking/live_tracking_config.dart';
import 'package:bmt_app/core/tracking/progress/route_stop.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

import 'tracking_test_harness.dart';

/// `LiveTrackingBloc` — the orchestration point for one rider's live view.
///
/// The tests are grouped by the thing that can go wrong rather than by method,
/// because that is what the events are: five independent producers pushing at
/// one state machine in orders nobody chooses.
void main() {
  late FakeTrackingDatasource datasource;
  late LiveTrackingBloc bloc;

  /// A clock the test moves by hand, so freshness is decided by elapsed time
  /// rather than by how long the test itself took to run.
  late DateTime now;

  const config = LiveTrackingConfig(staleAfter: Duration(seconds: 45));

  setUp(() {
    now = DateTime.utc(2026, 8, 17, 9);
    datasource = FakeTrackingDatasource(
      trip: _trip(state: TrackingTripState.inProgress),
    );
    bloc = buildLiveTrackingBloc(datasource, config: config, now: () => now);
  });

  tearDown(() async {
    await bloc.close();
    await datasource.dispose();
  });

  /// Lets the feed's events reach the bloc and the bloc's handlers run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<void> startTracking() async {
    bloc.add(TrackingRequested(datasource.trip));
    await settle();
  }

  group('opening a feed', () {
    test('starts connecting, then goes live on the first position', () async {
      await startTracking();
      expect(bloc.state, isA<LiveTrackingConnecting>());

      datasource.emitFix(latitude: 30.05, longitude: 31.23, recordedAt: now);
      await settle();

      final state = bloc.state as LiveTrackingActive;
      expect(state.fix.latitude, 30.05);
      expect(state.freshness, TrackingFreshness.live);
      expect(state.link, TrackingLink.connected);
      expect(state.isLive, isTrue);
    });

    test('subscribes to the feed exactly once', () async {
      await startTracking();

      expect(datasource.feedSubscriptions, 1);
      expect(datasource.feed.hasListener, isTrue);
    });

    test('a refetch of the same trip keeps the socket it already has', () async {
      await startTracking();
      datasource.emitFix(latitude: 30.05, longitude: 31.23, recordedAt: now);
      await settle();

      // The trip-change stream fires constantly during a live trip; each one
      // re-requests. Re-subscribing would drop a healthy socket every time and
      // lose the engine's monotonic stop history with it.
      bloc.add(TrackingRequested(datasource.trip));
      await settle();

      expect(datasource.feedSubscriptions, 1);
      expect(bloc.state, isA<LiveTrackingActive>());
    });

    test('carries real progress before any GPS, from confirmed arrivals',
        () async {
      datasource.trip = _trip(
        state: TrackingTripState.inProgress,
        arrivalEventCount: 2,
      );
      await startTracking();

      final progress = bloc.state.progress!;
      expect(progress.hasVehicleFix, isFalse);
      expect(progress.stops[0].status, StopVisitStatus.departed);
      expect(progress.stops[1].status, StopVisitStatus.arrived);
      expect(
        progress.stops[2].isVisited,
        isFalse,
        reason:
            'the captain\'s confirmed arrivals are an authoritative floor under '
            'GPS inference, not a substitute for it',
      );
    });
  });

  group('who may watch', () {
    test('a boarded rider gets no feed at all', () async {
      datasource.trip = _trip(
        state: TrackingTripState.inProgress,
        rider: const TrackingRider(bookingStatus: 'boarded'),
      );
      await startTracking();

      expect(bloc.state, isA<LiveTrackingUnavailable>());
      expect(
        datasource.feedSubscriptions,
        0,
        reason:
            'not merely marker-less — the subscription is never opened, so no '
            'socket is held for rows the server would refuse anyway',
      );
      expect(
        bloc.state.progress,
        isNotNull,
        reason: 'the route and their stops are still their journey',
      );
    });

    test('a finished trip is not subscribed to', () async {
      datasource.trip = _trip(state: TrackingTripState.completed);
      await startTracking();

      expect(bloc.state, isA<LiveTrackingFinished>());
      expect(datasource.feedSubscriptions, 0);
    });

    test('a trip with no id is simply idle', () async {
      datasource.trip = const TrackingTripData.none();
      await startTracking();

      expect(bloc.state, isA<LiveTrackingIdle>());
    });
  });

  group('positions that must change nothing', () {
    Future<void> live() async {
      await startTracking();
      datasource.emitFix(latitude: 30.05, longitude: 31.23, recordedAt: now);
      await settle();
    }

    test('a re-delivered fix emits no state', () async {
      await live();
      final states = <LiveTrackingState>[];
      final sub = bloc.stream.listen(states.add);

      // Exactly what the catch-up poll does when it overlaps with realtime.
      datasource.emitFix(latitude: 30.05, longitude: 31.23, recordedAt: now);
      await settle();

      expect(
        states,
        isEmpty,
        reason:
            'this is what makes the reconnect poll free: overlapping with the '
            'socket cannot cost a rebuild',
      );
      await sub.cancel();
    });

    test('an out-of-order fix emits no state', () async {
      await live();
      final states = <LiveTrackingState>[];
      final sub = bloc.stream.listen(states.add);

      datasource.emitFix(
        latitude: 30.06,
        longitude: 31.24,
        recordedAt: now.subtract(const Duration(seconds: 30)),
      );
      await settle();

      expect(states, isEmpty);
      await sub.cancel();
    });

    test('a junk (0,0) fix emits no state', () async {
      await live();
      final states = <LiveTrackingState>[];
      final sub = bloc.stream.listen(states.add);

      datasource.emitFix(
        latitude: 0,
        longitude: 0,
        recordedAt: now.add(const Duration(seconds: 10)),
      );
      await settle();

      expect(states, isEmpty);
      await sub.cancel();
    });

    test('a coarse fix is still accepted, unlike at the producer', () async {
      await live();

      datasource.emitFix(
        latitude: 30.0505,
        longitude: 31.2305,
        recordedAt: now.add(const Duration(seconds: 10)),
        accuracy: 400,
      );
      await settle();

      expect(
        (bloc.state as LiveTrackingActive).fix.accuracy,
        400,
        reason:
            'the captain rejects a coarse fix because a better one is seconds '
            'away; down here it is the only fix there is, and refusing it would '
            'freeze progress rather than improve it',
      );
    });
  });

  group('freshness', () {
    test('goes stale once nothing has landed for the stale window', () async {
      await startTracking();
      datasource.emitFix(latitude: 30.05, longitude: 31.23, recordedAt: now);
      await settle();
      expect((bloc.state as LiveTrackingActive).freshness,
          TrackingFreshness.live);

      now = now.add(const Duration(seconds: 46));
      bloc.add(const TrackingFreshnessEvaluated());
      await settle();

      final state = bloc.state as LiveTrackingActive;
      expect(state.freshness, TrackingFreshness.stale);
      expect(state.isLive, isFalse);
      expect(
        state.fix,
        isNotNull,
        reason:
            'the marker stays and is labelled — a rider watching a bus does not '
            'want it to vanish, they want to know not to trust it',
      );
    });

    test('a new position brings it back to live', () async {
      await startTracking();
      datasource.emitFix(latitude: 30.05, longitude: 31.23, recordedAt: now);
      await settle();
      now = now.add(const Duration(seconds: 46));
      bloc.add(const TrackingFreshnessEvaluated());
      await settle();
      expect((bloc.state as LiveTrackingActive).freshness,
          TrackingFreshness.stale);

      datasource.emitFix(latitude: 30.06, longitude: 31.24, recordedAt: now);
      await settle();

      expect((bloc.state as LiveTrackingActive).freshness,
          TrackingFreshness.live);
    });

    test('an unchanged verdict inside the ETA window emits nothing', () async {
      await startTracking();
      datasource.emitFix(latitude: 30.05, longitude: 31.23, recordedAt: now);
      await settle();

      final states = <LiveTrackingState>[];
      final sub = bloc.stream.listen(states.add);
      now = now.add(const Duration(seconds: 5));
      bloc.add(const TrackingFreshnessEvaluated());
      await settle();

      expect(
        states,
        isEmpty,
        reason: 'a tick that learned nothing must not repaint anything',
      );
      await sub.cancel();
    });

    test('a standing ETA is still re-counted as time passes', () async {
      await startTracking();
      datasource.emitFix(latitude: 30.05, longitude: 31.23, recordedAt: now);
      await settle();

      final states = <LiveTrackingState>[];
      final sub = bloc.stream.listen(states.add);
      // Past the ETA refresh interval but not yet stale.
      now = now.add(const Duration(seconds: 31));
      bloc.add(const TrackingFreshnessEvaluated());
      await settle();

      expect(
        states,
        hasLength(1),
        reason:
            '"12 minutes away" has to become "11 minutes away" without the bus '
            'doing anything',
      );
      expect((states.single as LiveTrackingActive).freshness,
          TrackingFreshness.live);
      await sub.cancel();
    });

    test('freshness is ignored while there is no position', () async {
      await startTracking();
      final states = <LiveTrackingState>[];
      final sub = bloc.stream.listen(states.add);

      now = now.add(const Duration(minutes: 5));
      bloc.add(const TrackingFreshnessEvaluated());
      await settle();

      expect(states, isEmpty);
      await sub.cancel();
    });
  });

  group('the link', () {
    Future<LiveTrackingActive> liveState() async {
      await startTracking();
      datasource.emitFix(latitude: 30.05, longitude: 31.23, recordedAt: now);
      await settle();
      return bloc.state as LiveTrackingActive;
    }

    test('degrading is reported without losing the position', () async {
      final before = await liveState();

      datasource.emitLink(TrackingLink.degraded);
      await settle();

      final after = bloc.state as LiveTrackingActive;
      expect(after.link, TrackingLink.degraded);
      expect(after.freshness, TrackingFreshness.live);
      expect(after.isLive, isFalse, reason: 'live means fresh AND connected');
      expect(after.fix.latitude, before.fix.latitude);
    });

    test('recovers to connected', () async {
      await liveState();
      datasource.emitLink(TrackingLink.lost);
      await settle();
      expect((bloc.state as LiveTrackingActive).link, TrackingLink.lost);

      datasource.emitLink(TrackingLink.connected);
      await settle();

      expect((bloc.state as LiveTrackingActive).link, TrackingLink.connected);
    });

    test('the same link twice emits nothing', () async {
      await liveState();
      final states = <LiveTrackingState>[];
      final sub = bloc.stream.listen(states.add);

      // Supabase re-reports `subscribed` on every rejoin.
      datasource.emitLink(TrackingLink.connected);
      datasource.emitLink(TrackingLink.connected);
      await settle();

      expect(states, isEmpty);
      await sub.cancel();
    });

    test('link news before the first position changes nothing on screen',
        () async {
      await startTracking();
      final states = <LiveTrackingState>[];
      final sub = bloc.stream.listen(states.add);

      datasource.emitLink(TrackingLink.degraded);
      await settle();

      expect(
        states,
        isEmpty,
        reason:
            'with nothing drawn there is nothing for link health to qualify; '
            '"connecting" is the honest answer either way',
      );
      expect(bloc.state, isA<LiveTrackingConnecting>());
      await sub.cancel();
    });
  });

  group('stopping', () {
    test('a stop releases the feed and goes idle', () async {
      await startTracking();
      expect(datasource.feed.hasListener, isTrue);

      bloc.add(const TrackingStopped());
      await settle();

      expect(bloc.state, isA<LiveTrackingIdle>());
      expect(datasource.feed.hasListener, isFalse);
    });

    test('finishing releases the feed and keeps the last progress', () async {
      await startTracking();
      datasource.emitFix(latitude: 30.05, longitude: 31.23, recordedAt: now);
      await settle();
      final progress = bloc.state.progress;

      bloc.add(const TrackingFinished());
      await settle();

      expect(bloc.state, isA<LiveTrackingFinished>());
      expect(
        bloc.state.progress,
        same(progress),
        reason: 'a completed journey still renders',
      );
      expect(
        datasource.feed.hasListener,
        isFalse,
        reason: 'a finished trip has no more positions; the socket costs nothing '
            'to nobody',
      );
    });

    test('positions arriving after a stop are ignored', () async {
      await startTracking();
      bloc.add(const TrackingStopped());
      await settle();

      datasource.emitFix(latitude: 30.05, longitude: 31.23, recordedAt: now);
      await settle();

      expect(bloc.state, isA<LiveTrackingIdle>());
    });

    test('closing leaves nothing running', () async {
      await startTracking();
      datasource.emitFix(latitude: 30.05, longitude: 31.23, recordedAt: now);
      await settle();

      await bloc.close();

      expect(
        datasource.feed.hasListener,
        isFalse,
        reason: 'the subscription goes with the bloc',
      );
      // The freshness timer goes too — a leaked periodic timer would fail any
      // widget test that mounted this screen.
    });
  });

  group('failure and retry', () {
    test('a feed error becomes a failure state, keeping what was drawn',
        () async {
      await startTracking();
      datasource.emitFix(latitude: 30.05, longitude: 31.23, recordedAt: now);
      await settle();

      datasource.feed.addError(Exception('socket died'));
      await settle();

      final state = bloc.state as LiveTrackingFailure;
      expect(state.message, 'socket died');
      expect(state.canRetry, isTrue);
      expect(state.progress, isNotNull);
      expect(datasource.feed.hasListener, isFalse);
    });

    test('a retry re-opens the feed', () async {
      await startTracking();
      datasource.feed.addError(Exception('socket died'));
      await settle();
      expect(bloc.state, isA<LiveTrackingFailure>());

      bloc.add(const TrackingRetryRequested());
      await settle();

      expect(datasource.feedSubscriptions, 2);
      expect(bloc.state, isA<LiveTrackingConnecting>());
    });

    test('hammering retry opens one feed, not one per tap', () async {
      await startTracking();
      datasource.feed.addError(Exception('socket died'));
      await settle();

      bloc
        ..add(const TrackingRetryRequested())
        ..add(const TrackingRetryRequested())
        ..add(const TrackingRetryRequested());
      await settle();

      expect(
        datasource.feedSubscriptions,
        2,
        reason:
            'the droppable transformer is what makes this true — three '
            'concurrent handlers would each open a socket',
      );
    });

    test('a retry with nothing ever requested does nothing', () async {
      bloc.add(const TrackingRetryRequested());
      await settle();

      expect(bloc.state, isA<LiveTrackingIdle>());
      expect(datasource.feedSubscriptions, 0);
    });
  });

  group('under load', () {
    test('fifty positions arrive in order, none dropped', () async {
      await startTracking();
      final states = <LiveTrackingState>[];
      final sub = bloc.stream.listen(states.add);

      for (var i = 1; i <= 50; i++) {
        datasource.emitFix(
          latitude: 30.05 + i * 0.0005,
          longitude: 31.23,
          recordedAt: now.add(Duration(seconds: i * 10)),
        );
      }
      await settle();

      expect(
        states,
        hasLength(50),
        reason:
            'sequential, not droppable: a rate limit belongs at the producer, '
            'and the newest position is the one that matters most',
      );
      final latitudes = states
          .cast<LiveTrackingActive>()
          .map((s) => s.fix.latitude)
          .toList();
      expect(
        latitudes,
        orderedEquals(List.generate(50, (i) => 30.05 + (i + 1) * 0.0005)),
        reason: 'folded into a stateful engine in the order they were reported',
      );
      await sub.cancel();
    });

    test('re-targeting to another trip abandons the first feed', () async {
      await startTracking();
      final first = datasource.feed.hasListener;

      datasource.trip = _trip(
        state: TrackingTripState.inProgress,
        tripId: 'trip-2',
      );
      bloc.add(TrackingRequested(datasource.trip));
      await settle();

      expect(first, isTrue);
      expect(
        datasource.feedSubscriptions,
        2,
        reason: 'a new trip is a new feed, and only one is held at a time',
      );
      expect(bloc.state, isA<LiveTrackingConnecting>());
    });
  });
}

TrackingTripData _trip({
  required TrackingTripState state,
  String tripId = 'trip-1',
  int arrivalEventCount = 0,
  TrackingRider rider = const TrackingRider(bookingStatus: 'confirmed'),
}) {
  return TrackingTripData(
    tripId: tripId,
    bookingId: 'booking-1',
    tripState: state,
    arrivalEventCount: arrivalEventCount,
    rider: rider,
    stops: const [
      RouteStop(name: 'Banha', latitude: 30.46, longitude: 31.18, order: 0),
      RouteStop(name: 'Nasr City', latitude: 30.06, longitude: 31.34, order: 1),
      RouteStop(name: 'Smart Village', latitude: 30.07, longitude: 31.01, order: 2),
    ],
  );
}
