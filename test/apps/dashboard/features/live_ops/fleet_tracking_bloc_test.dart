import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/tracking/link_health.dart';
import 'package:bmt_app/core/tracking/live_tracking_config.dart';

import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/fleet_feed.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/live_ops_snapshot.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/trip_incident.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/repositories/live_ops_repository.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/usecases/live_ops_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/bloc/fleet_tracking_bloc.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/bloc/fleet_tracking_event.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/bloc/fleet_tracking_state.dart';

/// A repository whose feed the test drives by hand, and which counts how many
/// times it was subscribed to — the only way to catch a Bloc that leaks sockets.
class _FakeRepo implements LiveOpsRepository {
  _FakeRepo({this.failFixes = false});

  final controller = StreamController<FleetFeedEvent>.broadcast();
  int subscriptions = 0;
  int cancellations = 0;
  int fixFetches = 0;
  Map<String, LiveFix> latest = const {};
  final bool failFixes;

  @override
  Stream<FleetFeedEvent> watchFleetFixes() {
    subscriptions++;
    // Wraps the broadcast source so each listen/cancel pair is observable.
    late StreamController<FleetFeedEvent> proxy;
    StreamSubscription<FleetFeedEvent>? sub;
    proxy = StreamController<FleetFeedEvent>(
      onListen: () =>
          sub = controller.stream.listen(proxy.add, onError: proxy.addError),
      onCancel: () {
        cancellations++;
        return sub?.cancel();
      },
    );
    return proxy.stream;
  }

  @override
  Future<Map<String, LiveFix>> fetchLatestFixes() async {
    fixFetches++;
    if (failFixes) throw Exception('rpc down');
    return latest;
  }

  @override
  Future<LiveOpsSnapshot> getSnapshot() async =>
      LiveOpsSnapshot.empty(DateTime(2026, 8, 17));

  @override
  Stream<void> watchChanges() => const Stream.empty();

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus next,
    String? note,
  }) async {}
}

LiveFix _fix({
  double lat = 30.0,
  double lng = 31.0,
  required DateTime at,
  double? speedKph,
}) =>
    LiveFix(latitude: lat, longitude: lng, recordedAt: at, speedKph: speedKph);

LiveTrip _trip({required String id, LiveFix? fix}) => LiveTrip(
  id: id,
  statusLabel: 'جارية',
  isInProgress: true,
  routeName: 'القاهرة — الإسكندرية',
  driverName: 'كابتن',
  driverPhone: '',
  vehicleLabel: 'ABC 123',
  tripDate: '2026-08-17',
  departureTime: '08:00',
  capacity: 14,
  bookedSeats: 7,
  lastFix: fix,
);

void main() {
  late _FakeRepo repo;
  late DateTime clock;

  FleetTrackingBloc build() => FleetTrackingBloc(
    watchFleetFeed: WatchFleetFeedUseCase(repo),
    getLatestFixes: GetLatestFleetFixesUseCase(repo),
    now: () => clock,
  );

  setUp(() {
    repo = _FakeRepo();
    clock = DateTime(2026, 8, 17, 9, 0);
  });

  /// Lets the feed's listener run and the resulting event be handled.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('subscription lifecycle', () {
    test('starting twice opens exactly one subscription', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(const FleetTrackingStarted());
      await settle();

      expect(repo.subscriptions, 1);
      await bloc.close();
    });

    test('close releases the feed', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      await settle();
      await bloc.close();

      expect(repo.cancellations, 1);
    });

    test('stopping releases the feed and clears positions', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(FleetTripsChanged([_trip(id: 'a')]));
      await settle();

      repo.controller.add(
        FleetFixReported(
          tripId: 'a',
          fix: _fix(at: clock),
        ),
      );
      await settle();
      expect(bloc.state.vehicles, hasLength(1));

      bloc.add(const FleetTrackingStopped());
      await settle();

      expect(bloc.state.vehicles, isEmpty);
      expect(repo.cancellations, 1);
      await bloc.close();
    });

    test('a retry releases the old feed before opening a new one', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      await settle();

      bloc.add(const FleetTrackingRetryRequested());
      await settle();

      expect(repo.cancellations, 1);
      expect(repo.subscriptions, 2);
      await bloc.close();
    });
  });

  group('positions', () {
    test('a fix for a roster trip is accepted', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(FleetTripsChanged([_trip(id: 'a')]));
      await settle();

      repo.controller.add(
        FleetFixReported(
          tripId: 'a',
          fix: _fix(lat: 30.5, at: clock),
        ),
      );
      await settle();

      expect(bloc.state.vehicle('a')!.fix.latitude, 30.5);
      expect(bloc.state.healthOf('a', clock), TrackingHealth.live);
      await bloc.close();
    });

    test('a fix for a trip not on the roster is dropped', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(FleetTripsChanged([_trip(id: 'a')]));
      await settle();

      repo.controller.add(
        FleetFixReported(
          tripId: 'ghost',
          fix: _fix(at: clock),
        ),
      );
      await settle();

      expect(bloc.state.vehicle('ghost'), isNull);
      expect(bloc.state.vehicles, isEmpty);
      await bloc.close();
    });

    test('a stale re-delivery emits no new state at all', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(FleetTripsChanged([_trip(id: 'a')]));
      await settle();

      repo.controller.add(
        FleetFixReported(
          tripId: 'a',
          fix: _fix(at: clock),
        ),
      );
      await settle();

      final emissions = <FleetTrackingState>[];
      final sub = bloc.stream.listen(emissions.add);

      // The same position again, and an older one — the overlap between the
      // socket and the catch-up poll. Neither may cost a rebuild.
      repo.controller.add(
        FleetFixReported(
          tripId: 'a',
          fix: _fix(at: clock),
        ),
      );
      repo.controller.add(
        FleetFixReported(
          tripId: 'a',
          fix: _fix(at: clock.subtract(const Duration(seconds: 30))),
        ),
      );
      await settle();

      expect(emissions, isEmpty);
      await sub.cancel();
      await bloc.close();
    });

    test('fifty fixes are applied in order, newest last', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(FleetTripsChanged([_trip(id: 'a')]));
      await settle();

      for (var i = 1; i <= 50; i++) {
        repo.controller.add(
          FleetFixReported(
            tripId: 'a',
            fix: _fix(
              lat: 30.0 + i / 1000,
              at: clock.add(Duration(seconds: i)),
            ),
          ),
        );
      }
      await settle();

      expect(bloc.state.vehicle('a')!.fix.latitude, closeTo(30.05, 1e-9));
      await bloc.close();
    });
  });

  group('roster', () {
    test('seeds positions from the roster backfill', () async {
      final bloc = build();
      final seededAt = clock.subtract(const Duration(seconds: 10));

      bloc.add(const FleetTrackingStarted());
      bloc.add(
        FleetTripsChanged([
          _trip(
            id: 'a',
            fix: _fix(at: seededAt),
          ),
        ]),
      );
      await settle();

      expect(bloc.state.vehicle('a'), isNotNull);
      // Seeded at the fix's own time, so an already-old backfill is not
      // laundered into a fresh one.
      expect(bloc.state.vehicle('a')!.receivedAt, seededAt);
      await bloc.close();
    });

    test('a stale backfill is reported stale, not live', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(
        FleetTripsChanged([
          _trip(
            id: 'a',
            fix: _fix(at: clock.subtract(const Duration(minutes: 2))),
          ),
        ]),
      );
      await settle();

      expect(bloc.state.healthOf('a', clock), TrackingHealth.stale);
      await bloc.close();
    });

    test('a trip leaving the roster takes its position with it', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(FleetTripsChanged([_trip(id: 'a'), _trip(id: 'b')]));
      await settle();

      repo.controller.add(
        FleetFixReported(
          tripId: 'a',
          fix: _fix(at: clock),
        ),
      );
      repo.controller.add(
        FleetFixReported(
          tripId: 'b',
          fix: _fix(at: clock),
        ),
      );
      await settle();
      expect(bloc.state.vehicles, hasLength(2));

      bloc.add(FleetTripsChanged([_trip(id: 'a')]));
      await settle();

      expect(bloc.state.vehicles.keys.single, 'a');
      await bloc.close();
    });

    test('a live position survives a roster refresh', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(FleetTripsChanged([_trip(id: 'a')]));
      await settle();

      repo.controller.add(
        FleetFixReported(
          tripId: 'a',
          fix: _fix(lat: 31.9, at: clock),
        ),
      );
      await settle();

      // The roster comes back carrying its older seed; the live fix must win.
      bloc.add(
        FleetTripsChanged([
          _trip(
            id: 'a',
            fix: _fix(
              lat: 30.0,
              at: clock.subtract(const Duration(minutes: 5)),
            ),
          ),
        ]),
      );
      await settle();

      expect(bloc.state.vehicle('a')!.fix.latitude, 31.9);
      await bloc.close();
    });
  });

  group('link health', () {
    test('a degraded link starts the catch-up poll immediately', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(FleetTripsChanged([_trip(id: 'a')]));
      await settle();

      expect(repo.fixFetches, 0, reason: 'healthy link must not poll');

      repo.latest = {'a': _fix(lat: 29.1, at: clock)};
      repo.controller.add(const FleetLinkChanged(TrackingLink.degraded));
      await settle();

      expect(repo.fixFetches, 1);
      expect(bloc.state.vehicle('a')!.fix.latitude, 29.1);
      expect(bloc.state.link, TrackingLink.degraded);
      await bloc.close();
    });

    test('a healthy link issues no position queries', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(FleetTripsChanged([_trip(id: 'a')]));
      // The feed is a broadcast source: nothing may be pushed into it before the
      // Bloc has actually subscribed, or the event goes nowhere.
      await settle();

      repo.controller.add(const FleetLinkChanged(TrackingLink.connected));
      await settle();

      expect(repo.fixFetches, 0);
      expect(bloc.state.isConnecting, isFalse);
      await bloc.close();
    });

    test('recovering stops the catch-up poll', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(FleetTripsChanged([_trip(id: 'a')]));
      await settle();

      repo.controller.add(const FleetLinkChanged(TrackingLink.degraded));
      await settle();
      final whileDegraded = repo.fixFetches;

      repo.controller.add(const FleetLinkChanged(TrackingLink.connected));
      await settle();

      expect(repo.fixFetches, whileDegraded);
      expect(bloc.state.link, TrackingLink.connected);
      await bloc.close();
    });

    test('a failed catch-up read is swallowed, positions kept', () async {
      repo = _FakeRepo(failFixes: true);
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(FleetTripsChanged([_trip(id: 'a')]));
      await settle();

      repo.controller.add(
        FleetFixReported(
          tripId: 'a',
          fix: _fix(lat: 30.7, at: clock),
        ),
      );
      repo.controller.add(const FleetLinkChanged(TrackingLink.degraded));
      await settle();

      expect(bloc.state.vehicle('a')!.fix.latitude, 30.7);
      expect(bloc.state.hasFailure, isFalse);
      await bloc.close();
    });
  });

  group('failure', () {
    test('a feed error keeps the last known positions on screen', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(FleetTripsChanged([_trip(id: 'a')]));
      await settle();

      repo.controller.add(
        FleetFixReported(
          tripId: 'a',
          fix: _fix(lat: 30.3, at: clock),
        ),
      );
      await settle();

      repo.controller.addError(Exception('socket died'));
      await settle();

      expect(bloc.state.hasFailure, isTrue);
      expect(bloc.state.failure, 'socket died');
      expect(bloc.state.link, TrackingLink.lost);
      // The map must not go blank: last known is still the best answer there is.
      expect(bloc.state.vehicle('a')!.fix.latitude, 30.3);
      await bloc.close();
    });

    test('a position arriving clears a stale failure', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(FleetTripsChanged([_trip(id: 'a')]));
      await settle();

      repo.controller.addError(Exception('socket died'));
      await settle();
      expect(bloc.state.hasFailure, isTrue);

      bloc.add(const FleetTrackingRetryRequested());
      await settle();
      expect(bloc.state.hasFailure, isFalse);

      repo.controller.add(
        FleetFixReported(
          tripId: 'a',
          fix: _fix(at: clock),
        ),
      );
      await settle();

      expect(bloc.state.hasFailure, isFalse);
      await bloc.close();
    });
  });

  group('freshness', () {
    test('a vehicle goes stale as the clock advances', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(FleetTripsChanged([_trip(id: 'a')]));
      await settle();

      repo.controller.add(
        FleetFixReported(
          tripId: 'a',
          fix: _fix(at: clock),
        ),
      );
      await settle();
      expect(bloc.state.healthOf('a', clock), TrackingHealth.live);

      final later = clock
          .add(kLiveTrackingConfig.staleAfter)
          .add(const Duration(seconds: 1));
      expect(bloc.state.healthOf('a', later), TrackingHealth.stale);
      await bloc.close();
    });

    test('an empty board never emits a freshness tick', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      await settle();

      final emissions = <FleetTrackingState>[];
      final sub = bloc.stream.listen(emissions.add);

      bloc.add(const FleetFreshnessEvaluated());
      await settle();

      expect(emissions, isEmpty);
      await sub.cancel();
      await bloc.close();
    });

    test('a tick advances the board clock when vehicles exist', () async {
      final bloc = build();
      bloc.add(const FleetTrackingStarted());
      bloc.add(FleetTripsChanged([_trip(id: 'a')]));
      await settle();

      repo.controller.add(
        FleetFixReported(
          tripId: 'a',
          fix: _fix(at: clock),
        ),
      );
      await settle();
      final before = bloc.state.evaluatedAt;

      clock = clock.add(const Duration(seconds: 15));
      bloc.add(const FleetFreshnessEvaluated());
      await settle();

      expect(bloc.state.evaluatedAt, isNot(before));
      await bloc.close();
    });
  });

  group('at-risk counting', () {
    test('counts everything that is not live, including never-reported', () {
      final now = DateTime(2026, 8, 17, 9, 0);
      final state = FleetTrackingState(
        vehicles: {
          'live': TrackedVehicle(
            fix: _fix(at: now),
            receivedAt: now.subtract(const Duration(seconds: 5)),
          ),
          'stale': TrackedVehicle(
            fix: _fix(at: now),
            receivedAt: now.subtract(const Duration(minutes: 2)),
          ),
        },
      );

      expect(state.atRiskCount(['live', 'stale', 'never'], now), 2);
    });
  });
}
