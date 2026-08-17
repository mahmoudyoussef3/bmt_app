import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/tracking/live_tracking_config.dart';

import 'package:bmt_app/apps/dashboard/features/live_ops/data/models/live_trip_model.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/data/models/trip_incident_model.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/fleet_feed.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/live_ops_snapshot.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/trip_incident.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/repositories/live_ops_repository.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/usecases/live_ops_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/bloc/fleet_tracking_state.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/cubit/live_ops_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/cubit/live_ops_state.dart';

LiveTrip _trip({
  String id = 't1',
  bool inProgress = true,
  LiveFix? fix,
  int capacity = 14,
  int booked = 7,
  DateTime? scheduledDeparture,
  DateTime? actualStart,
}) {
  return LiveTrip(
    id: id,
    statusLabel: inProgress ? 'جارية' : 'صعود الركاب',
    isInProgress: inProgress,
    routeName: 'المنصورة - القاهرة',
    driverName: 'أحمد',
    driverPhone: '0100',
    vehicleLabel: 'ABC 123',
    tripDate: '2026-07-27',
    departureTime: '08:00',
    capacity: capacity,
    bookedSeats: booked,
    lastFix: fix,
    scheduledDeparture: scheduledDeparture,
    actualStart: actualStart,
  );
}

LiveFix _fixAgo(DateTime now, Duration age) =>
    LiveFix(latitude: 30.0, longitude: 31.0, recordedAt: now.subtract(age));

TripIncident _incident({
  String id = 'i1',
  IncidentType type = IncidentType.delay,
  IncidentStatus status = IncidentStatus.pending,
  DateTime? createdAt,
}) {
  return TripIncident(
    id: id,
    tripId: 't1',
    type: type,
    description: 'وصف',
    status: status,
    createdAt: createdAt ?? DateTime(2026, 7, 27, 8),
  );
}

void main() {
  group('TrackingHealth.fromFixAge', () {
    test('null age is unknown', () {
      expect(TrackingHealth.fromFixAge(null), TrackingHealth.unknown);
    });

    test('a fresh fix is live', () {
      expect(TrackingHealth.fromFixAge(Duration.zero), TrackingHealth.live);
      expect(
        TrackingHealth.fromFixAge(TrackingHealth.liveWindow),
        TrackingHealth.live,
      );
    });

    test('the live window is the platform-wide one, not a local guess', () {
      // The desk and the rider must call the same bus stale at the same moment.
      // This used to be a local 75s derived from a 30s captain cadence that no
      // longer exists, so a rider already seeing «تأخر الإشارة» could watch the
      // operator's board still read «حية».
      expect(TrackingHealth.liveWindow, kLiveTrackingConfig.staleAfter);
    });

    test('just past the live window is stale', () {
      expect(
        TrackingHealth.fromFixAge(
          TrackingHealth.liveWindow + const Duration(seconds: 1),
        ),
        TrackingHealth.stale,
      );
      expect(
        TrackingHealth.fromFixAge(const Duration(minutes: 4)),
        TrackingHealth.stale,
      );
    });

    test('past the stale window is offline', () {
      expect(
        TrackingHealth.fromFixAge(const Duration(minutes: 4, seconds: 1)),
        TrackingHealth.offline,
      );
      expect(
        TrackingHealth.fromFixAge(const Duration(hours: 1)),
        TrackingHealth.offline,
      );
    });
  });

  group('TrackedVehicle health & trip occupancy', () {
    final now = DateTime(2026, 7, 27, 8, 30);

    TrackedVehicle vehicleAgo(Duration age) =>
        TrackedVehicle(fix: _fixAgo(now, age), receivedAt: now.subtract(age));

    test('a vehicle with a recent fix reads live', () {
      expect(
        vehicleAgo(const Duration(seconds: 20)).healthAt(now),
        TrackingHealth.live,
      );
    });

    test('a trip with no vehicle at all reads unknown', () {
      const state = FleetTrackingState();
      expect(state.vehicle('t1'), isNull);
      expect(state.healthOf('t1', now), TrackingHealth.unknown);
    });

    test('a fix received slightly in the future reads fresh, not negative', () {
      expect(
        vehicleAgo(const Duration(seconds: -5)).healthAt(now),
        TrackingHealth.live,
      );
    });

    test('health is measured from receipt, not from the captain clock', () {
      // A device whose clock runs an hour fast must not keep a dead feed alive:
      // the fix claims the future, but it was received four minutes ago.
      final vehicle = TrackedVehicle(
        fix: _fixAgo(now, const Duration(hours: -1)),
        receivedAt: now.subtract(const Duration(minutes: 4, seconds: 30)),
      );
      expect(vehicle.healthAt(now), TrackingHealth.offline);
    });

    test('occupancy ratio guards a zero-capacity trip', () {
      expect(_trip(capacity: 0, booked: 0).occupancyRatio, 0);
      expect(_trip(capacity: 10, booked: 5).occupancyRatio, 0.5);
    });
  });

  group('LiveOpsSnapshot counts', () {
    final now = DateTime(2026, 7, 27, 8, 30);

    final snapshot = LiveOpsSnapshot(
      generatedAt: now,
      activeTrips: [
        _trip(id: 'a', fix: _fixAgo(now, const Duration(seconds: 20))), // live
        _trip(
          id: 'b',
          fix: _fixAgo(now, const Duration(minutes: 10)),
        ), // offline
        _trip(id: 'c', inProgress: false), // boarding, unknown
      ],
      incidents: [
        _incident(id: 'e', type: IncidentType.emergency), // critical, pending
        _incident(id: 'd', type: IncidentType.delay), // pending
        _incident(id: 'r', status: IncidentStatus.resolved), // resolved
      ],
    );

    test('separates in-progress from boarding', () {
      expect(snapshot.inProgressCount, 2);
      expect(snapshot.boardingCount, 1);
    });

    test('counts trips that are no longer live as at-risk', () {
      // The count is the feed's to make, not the roster's — the roster's fixes
      // are only the seed the board opened with.
      final feed = FleetTrackingState(
        vehicles: {
          'a': TrackedVehicle(
            fix: _fixAgo(now, const Duration(seconds: 20)),
            receivedAt: now.subtract(const Duration(seconds: 20)),
          ),
          'b': TrackedVehicle(
            fix: _fixAgo(now, const Duration(minutes: 10)),
            receivedAt: now.subtract(const Duration(minutes: 10)),
          ),
          // 'c' never reported at all.
        },
      );
      // offline + unknown = 2 (the live one is excluded).
      expect(feed.atRiskCount(snapshot.activeTrips.map((t) => t.id), now), 2);
    });

    test('open incidents exclude resolved and flag a critical one', () {
      expect(snapshot.openIncidentCount, 2);
      expect(snapshot.hasCriticalIncident, isTrue);
    });
  });

  group('Departure delay detection', () {
    final scheduled = DateTime(2026, 7, 27, 8);

    test('a boarding trip before its time is pending, with no delay', () {
      final trip = _trip(inProgress: false, scheduledDeparture: scheduled);
      final now = scheduled.subtract(const Duration(minutes: 5));
      expect(trip.departureStatusAt(now), DepartureStatus.pending);
      expect(trip.departureDelayAt(now), isNull);
      expect(trip.isOverdueAt(now), isFalse);
    });

    test('inside the boarding grace it is due, not late', () {
      final trip = _trip(inProgress: false, scheduledDeparture: scheduled);
      // Loading a bus routinely runs a few minutes past the clock.
      final now = scheduled.add(const Duration(minutes: 9));
      expect(trip.departureStatusAt(now), DepartureStatus.due);
      expect(trip.departureDelayAt(now), isNull);
      expect(trip.isOverdueAt(now), isFalse);
    });

    test('the grace boundary itself is still due', () {
      final trip = _trip(inProgress: false, scheduledDeparture: scheduled);
      final now = scheduled.add(boardingGrace);
      expect(trip.departureStatusAt(now), DepartureStatus.due);
    });

    test('past the grace a boarding trip is overdue and reports its delay', () {
      final trip = _trip(inProgress: false, scheduledDeparture: scheduled);
      final now = scheduled.add(const Duration(minutes: 35));
      expect(trip.departureStatusAt(now), DepartureStatus.overdue);
      expect(trip.departureDelayAt(now), const Duration(minutes: 35));
      expect(trip.isOverdueAt(now), isTrue);
    });

    test('a departed trip reports how late it actually left, not "now"', () {
      final trip = _trip(
        inProgress: true,
        scheduledDeparture: scheduled,
        actualStart: scheduled.add(const Duration(minutes: 25)),
      );
      // Hours later, the delay is still the 25 minutes it actually lost.
      final now = scheduled.add(const Duration(hours: 3));
      expect(trip.departureStatusAt(now), DepartureStatus.departed);
      expect(trip.departureDelayAt(now), const Duration(minutes: 25));
      // Already on the road, so it is never an "overdue" action item.
      expect(trip.isOverdueAt(now), isFalse);
    });

    test('a departed trip that left on time reports no delay', () {
      final trip = _trip(
        inProgress: true,
        scheduledDeparture: scheduled,
        actualStart: scheduled.add(const Duration(minutes: 2)),
      );
      expect(
        trip.departureDelayAt(scheduled.add(const Duration(hours: 1))),
        isNull,
      );
    });

    test('a departed trip with no recorded start reports null, never zero', () {
      final trip = _trip(inProgress: true, scheduledDeparture: scheduled);
      // An unknown delay must not render as "0 minutes late".
      expect(
        trip.departureDelayAt(scheduled.add(const Duration(hours: 1))),
        isNull,
      );
    });

    test('an unparseable schedule yields unknown, never a guessed delay', () {
      final trip = _trip(inProgress: false);
      expect(
        trip.departureStatusAt(DateTime(2026, 7, 27, 9)),
        DepartureStatus.unknown,
      );
      expect(trip.departureDelayAt(DateTime(2026, 7, 27, 9)), isNull);
      expect(trip.isOverdueAt(DateTime(2026, 7, 27, 9)), isFalse);
    });
  });

  group('LiveOpsSnapshot overdue reporting', () {
    final scheduled = DateTime(2026, 7, 27, 8);
    final now = scheduled.add(const Duration(minutes: 40));

    test('overdue trips are listed worst-first', () {
      final snapshot = LiveOpsSnapshot(
        generatedAt: now,
        activeTrips: [
          _trip(
            id: 'late15',
            inProgress: false,
            scheduledDeparture: now.subtract(const Duration(minutes: 15)),
          ),
          _trip(
            id: 'onTime',
            inProgress: false,
            scheduledDeparture: now.add(const Duration(minutes: 30)),
          ),
          _trip(id: 'late40', inProgress: false, scheduledDeparture: scheduled),
        ],
        incidents: const [],
      );

      expect(snapshot.overdueTrips(now).map((t) => t.id), ['late40', 'late15']);
      expect(snapshot.overdueCount(now), 2);
    });

    test('only trips with a fix are mappable', () {
      final snapshot = LiveOpsSnapshot(
        generatedAt: now,
        activeTrips: [
          _trip(id: 'a', fix: _fixAgo(now, const Duration(seconds: 10))),
          _trip(id: 'b'),
        ],
        incidents: const [],
      );
      // A trip with no position is never drawn at a guessed location, but it
      // stays in activeTrips so the list still shows it.
      expect(snapshot.mappableTrips.map((t) => t.id), ['a']);
      expect(snapshot.activeTrips.length, 2);
    });
  });

  group('IncidentStatus lifecycle', () {
    test('maps the database allowlist, unknown values read as pending', () {
      expect(IncidentStatus.fromDb('pending'), IncidentStatus.pending);
      expect(
        IncidentStatus.fromDb('acknowledged'),
        IncidentStatus.acknowledged,
      );
      expect(IncidentStatus.fromDb('resolved'), IncidentStatus.resolved);
      expect(IncidentStatus.fromDb('dismissed'), IncidentStatus.dismissed);
      // An unclassifiable report must still be visible and actionable.
      expect(IncidentStatus.fromDb('who_knows'), IncidentStatus.pending);
    });

    test('db strings round-trip', () {
      for (final status in IncidentStatus.values) {
        expect(IncidentStatus.fromDb(status.db), status);
      }
    });

    test('pending may be acknowledged, resolved or dismissed', () {
      const from = IncidentStatus.pending;
      expect(from.canTransitionTo(IncidentStatus.acknowledged), isTrue);
      expect(from.canTransitionTo(IncidentStatus.resolved), isTrue);
      expect(from.canTransitionTo(IncidentStatus.dismissed), isTrue);
    });

    test('acknowledged may only be closed, never reopened', () {
      const from = IncidentStatus.acknowledged;
      expect(from.canTransitionTo(IncidentStatus.resolved), isTrue);
      expect(from.canTransitionTo(IncidentStatus.dismissed), isTrue);
      // Reopening would erase the record of who took ownership.
      expect(from.canTransitionTo(IncidentStatus.pending), isFalse);
      expect(from.canTransitionTo(IncidentStatus.acknowledged), isFalse);
    });

    test('closed states are terminal', () {
      for (final terminal in [
        IncidentStatus.resolved,
        IncidentStatus.dismissed,
      ]) {
        expect(terminal.isClosed, isTrue);
        for (final next in IncidentStatus.values) {
          expect(terminal.canTransitionTo(next), isFalse);
        }
      }
      expect(IncidentStatus.pending.isClosed, isFalse);
      expect(IncidentStatus.acknowledged.isClosed, isFalse);
    });
  });

  group('UpdateIncidentStatusUseCase', () {
    test('rejects an illegal move without touching the repository', () async {
      final repo = _FakeRepo();
      final useCase = UpdateIncidentStatusUseCase(repo);

      expect(
        () => useCase(
          incident: _incident(status: IncidentStatus.resolved),
          next: IncidentStatus.acknowledged,
        ),
        throwsA(isA<InvalidIncidentTransition>()),
      );
      expect(repo.writes, isEmpty);
    });

    test('passes a legal move through with its note', () async {
      final repo = _FakeRepo(incidents: [_incident(id: 'i1')]);
      final useCase = UpdateIncidentStatusUseCase(repo);

      await useCase(
        incident: _incident(id: 'i1'),
        next: IncidentStatus.resolved,
        note: 'تم الحل',
      );

      expect(repo.writes.single.id, 'i1');
      expect(repo.writes.single.next, IncidentStatus.resolved);
      expect(repo.writes.single.note, 'تم الحل');
    });
  });

  group('Incident queue triage order', () {
    final now = DateTime(2026, 7, 27, 9);

    test('severity first, then unowned before owned, then oldest first', () {
      final snapshot = LiveOpsSnapshot(
        generatedAt: now,
        activeTrips: const [],
        incidents: [
          _incident(
            id: 'oldDelay',
            type: IncidentType.delay,
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
          _incident(
            id: 'newSos',
            type: IncidentType.emergency,
            createdAt: now.subtract(const Duration(minutes: 1)),
          ),
          _incident(
            id: 'ackedBreakdown',
            type: IncidentType.vehicleIssue,
            status: IncidentStatus.acknowledged,
            createdAt: now.subtract(const Duration(minutes: 30)),
          ),
          _incident(
            id: 'newBreakdown',
            type: IncidentType.vehicleIssue,
            createdAt: now.subtract(const Duration(minutes: 5)),
          ),
          _incident(id: 'closed', status: IncidentStatus.resolved),
        ],
      );

      expect(
        snapshot.openIncidents.map((i) => i.id),
        // SOS outranks an hours-old delay; within one severity an untouched
        // report outranks one someone already owns.
        ['newSos', 'newBreakdown', 'ackedBreakdown', 'oldDelay'],
      );
      expect(snapshot.openIncidentCount, 4);
      expect(snapshot.unacknowledgedCount, 3);
    });

    test('age is measured from creation and never negative', () {
      final incident = _incident(
        createdAt: now.add(const Duration(minutes: 5)),
      );
      expect(incident.ageAt(now), Duration.zero);
    });
  });

  group('IncidentType & severity mapping', () {
    test('maps captain report_type strings, including legacy shorthand', () {
      expect(IncidentType.fromDb('emergency'), IncidentType.emergency);
      expect(IncidentType.fromDb('sos'), IncidentType.emergency);
      expect(IncidentType.fromDb('vehicle_issue'), IncidentType.vehicleIssue);
      expect(IncidentType.fromDb('flat_tire'), IncidentType.vehicleIssue);
      expect(IncidentType.fromDb('traffic'), IncidentType.routeBlockage);
      expect(
        IncidentType.fromDb('passenger_no_show'),
        IncidentType.passengerIssue,
      );
      expect(IncidentType.fromDb('something_new'), IncidentType.other);
    });

    test('severity escalates emergencies above everything else', () {
      expect(
        _incident(type: IncidentType.emergency).severity,
        IncidentSeverity.critical,
      );
      expect(
        _incident(type: IncidentType.vehicleIssue).severity,
        IncidentSeverity.warning,
      );
      expect(
        _incident(type: IncidentType.delay).severity,
        IncidentSeverity.info,
      );
    });
  });

  group('Model mapping', () {
    test('LiveTripModel.fromRows maps embeds, seats and speed', () {
      final trip = LiveTripModel.fromRows(
        {
          'id': 't1',
          'status': 'in_progress',
          'trip_date': '2026-07-27',
          'departure_time': '08:00',
          'capacity': 14,
          'route': {'name': 'المنصورة - القاهرة'},
          'driver': {'full_name': 'أحمد', 'phone': '0100'},
          'vehicle': {'plate_number': 'ABC 123', 'vehicle_code': 'V-1'},
          'seats': [
            {'state': 'paid'},
            {'state': 'reserved'},
            {'state': 'subscription'},
            {'state': 'available'},
            {'state': 'blocked'},
          ],
        },
        fix: {
          'latitude': 30.0,
          'longitude': 31.0,
          'speed': 10.0, // m/s
          'heading': 90.0,
          'recorded_at': '2026-07-27T08:00:00Z',
        },
      );

      expect(trip.isInProgress, isTrue);
      expect(trip.routeName, 'المنصورة - القاهرة');
      expect(trip.vehicleLabel, 'ABC 123'); // plate preferred over code
      expect(trip.bookedSeats, 3); // paid + reserved + subscription
      expect(trip.capacity, 14);
      expect(trip.lastFix, isNotNull);
      expect(trip.lastFix!.speedKph, closeTo(36, 0.001)); // 10 m/s -> 36 km/h
    });

    test('LiveTripModel.fromRows tolerates a missing fix and empty embeds', () {
      final trip = LiveTripModel.fromRows({
        'id': 't2',
        'status': 'boarding',
        'capacity': 0,
        'seats': const [],
      });
      expect(trip.lastFix, isNull);
      expect(trip.isInProgress, isFalse);
      expect(trip.routeName, 'مسار غير معروف');
      expect(trip.driverName, 'غير معيّن');
      expect(trip.bookedSeats, 0);
    });

    test('TripIncidentModel.fromJson maps type, status and trip context', () {
      final incident = TripIncidentModel.fromJson({
        'id': 'i1',
        'trip_id': 't1',
        'report_type': 'emergency',
        'description': 'حادث بسيط',
        'status': 'pending',
        'created_at': '2026-07-27T08:00:00Z',
        'trip': {
          'trip_date': '2026-07-27',
          'departure_time': '08:00',
          'route': {'name': 'المنصورة - القاهرة'},
          'driver': {'full_name': 'أحمد'},
          'vehicle': {'plate_number': 'ABC 123'},
        },
      });

      expect(incident.type, IncidentType.emergency);
      expect(incident.severity, IncidentSeverity.critical);
      expect(incident.status, IncidentStatus.pending);
      expect(incident.isPending, isTrue);
      expect(incident.routeName, 'المنصورة - القاهرة');
      expect(incident.driverName, 'أحمد');
      expect(incident.vehicleLabel, 'ABC 123');
    });
  });

  group('LiveOpsCubit', () {
    LiveOpsCubit build(_FakeRepo repo) => LiveOpsCubit(
      getSnapshot: GetLiveOpsSnapshotUseCase(repo),
      watch: WatchLiveOpsUseCase(repo),
      updateIncident: UpdateIncidentStatusUseCase(repo),
    );

    test('load emits Loaded with the snapshot', () async {
      final repo = _FakeRepo(incidents: [_incident(id: 'i1')]);
      final cubit = build(repo);
      await cubit.load();
      expect(cubit.state, isA<LiveOpsLoaded>());
      expect((cubit.state as LiveOpsLoaded).snapshot.openIncidentCount, 1);
      await cubit.close();
    });

    test('load surfaces a full error state on first failure', () async {
      final repo = _FakeRepo(throwOnSnapshot: true);
      final cubit = build(repo);
      await cubit.load();
      expect(cubit.state, isA<LiveOpsError>());
      await cubit.close();
    });

    test('acknowledging keeps the report in the queue, now owned', () async {
      final repo = _FakeRepo(incidents: [_incident(id: 'i1')]);
      final cubit = build(repo);
      await cubit.load();
      final incident =
          (cubit.state as LiveOpsLoaded).snapshot.openIncidents.single;

      final error = await cubit.updateIncident(
        incident,
        IncidentStatus.acknowledged,
      );

      expect(error, isNull);
      final loaded = cubit.state as LiveOpsLoaded;
      // Still open — an acknowledged report must not vanish mid-handling.
      expect(loaded.snapshot.openIncidentCount, 1);
      expect(loaded.snapshot.openIncidents.single.isAcknowledged, isTrue);
      expect(loaded.snapshot.unacknowledgedCount, 0);
      await cubit.close();
    });

    test(
      'resolving with a note closes the report and records the note',
      () async {
        final repo = _FakeRepo(
          incidents: [
            _incident(id: 'i1'),
            _incident(id: 'i2'),
          ],
        );
        final cubit = build(repo);
        await cubit.load();
        final incident = (cubit.state as LiveOpsLoaded).snapshot.openIncidents
            .firstWhere((i) => i.id == 'i1');

        final error = await cubit.updateIncident(
          incident,
          IncidentStatus.resolved,
          note: 'تم إرسال مركبة بديلة',
        );

        expect(error, isNull);
        expect(repo.writes.single.note, 'تم إرسال مركبة بديلة');
        final loaded = cubit.state as LiveOpsLoaded;
        expect(loaded.snapshot.openIncidentCount, 1);
        expect(loaded.snapshot.openIncidents.single.id, 'i2');
        await cubit.close();
      },
    );

    test('an illegal transition is refused before any write', () async {
      final repo = _FakeRepo(
        incidents: [_incident(id: 'i1', status: IncidentStatus.resolved)],
      );
      final cubit = build(repo);
      await cubit.load();
      // A resolved report is terminal; a stale queue must not reopen it.
      final resolved = _incident(id: 'i1', status: IncidentStatus.resolved);

      final error = await cubit.updateIncident(
        resolved,
        IncidentStatus.acknowledged,
      );

      expect(error, isNotNull);
      expect(repo.writes, isEmpty);
      expect(cubit.state, isA<LiveOpsLoaded>());
      await cubit.close();
    });

    test('a failed update keeps the screen and reports the error', () async {
      final repo = _FakeRepo(
        incidents: [_incident(id: 'i1')],
        throwOnUpdate: true,
      );
      final cubit = build(repo);
      await cubit.load();
      final incident =
          (cubit.state as LiveOpsLoaded).snapshot.openIncidents.single;

      final error = await cubit.updateIncident(
        incident,
        IncidentStatus.acknowledged,
      );

      expect(error, isNotNull);
      // The live picture is preserved, not blanked, and carries the feedback.
      expect(cubit.state, isA<LiveOpsLoaded>());
      expect((cubit.state as LiveOpsLoaded).actionError, isNotNull);
      expect((cubit.state as LiveOpsLoaded).snapshot.openIncidentCount, 1);
      await cubit.close();
    });
  });

  group('LiveOpsCubit trip selection', () {
    LiveOpsCubit build(_FakeRepo repo) => LiveOpsCubit(
      getSnapshot: GetLiveOpsSnapshotUseCase(repo),
      watch: WatchLiveOpsUseCase(repo),
      updateIncident: UpdateIncidentStatusUseCase(repo),
    );

    test('selecting focuses a trip and re-selecting clears it', () async {
      final repo = _FakeRepo(
        trips: [
          _trip(id: 'a'),
          _trip(id: 'b'),
        ],
      );
      final cubit = build(repo);
      await cubit.load();

      cubit.selectTrip('a');
      expect((cubit.state as LiveOpsLoaded).selectedTripId, 'a');
      expect((cubit.state as LiveOpsLoaded).selectedTrip?.id, 'a');

      // Tapping the same trip again zooms back out.
      cubit.selectTrip('a');
      expect((cubit.state as LiveOpsLoaded).selectedTripId, isNull);
      await cubit.close();
    });

    test('selection survives a background refresh', () async {
      final repo = _FakeRepo(trips: [_trip(id: 'a')]);
      final cubit = build(repo);
      await cubit.load();
      cubit.selectTrip('a');

      await cubit.refresh();

      expect((cubit.state as LiveOpsLoaded).selectedTripId, 'a');
      await cubit.close();
    });

    test(
      'a selected trip that ends resolves to null without crashing',
      () async {
        final repo = _FakeRepo(trips: [_trip(id: 'a')]);
        final cubit = build(repo);
        await cubit.load();
        cubit.selectTrip('a');

        // The trip completes and leaves the active set.
        repo._trips.clear();
        await cubit.refresh();

        final loaded = cubit.state as LiveOpsLoaded;
        expect(loaded.selectedTripId, 'a');
        // Resolved through the snapshot, so a stale id yields no trip rather
        // than a dangling reference.
        expect(loaded.selectedTrip, isNull);
        await cubit.close();
      },
    );
  });
}

/// In-memory repository. Holds a mutable incident list so a lifecycle move is
/// observable on the next snapshot, mirroring the real refresh path.
class _FakeRepo implements LiveOpsRepository {
  _FakeRepo({
    List<TripIncident> incidents = const [],
    List<LiveTrip> trips = const [],
    this.throwOnSnapshot = false,
    this.throwOnUpdate = false,
  }) : _incidents = [...incidents],
       _trips = [...trips];

  final List<TripIncident> _incidents;
  final List<LiveTrip> _trips;
  final bool throwOnSnapshot;
  final bool throwOnUpdate;

  /// Every write the cubit performed, so tests can assert what reached the
  /// data layer (and that an illegal move reached it never).
  final List<({String id, IncidentStatus next, String? note})> writes = [];

  @override
  Stream<FleetFeedEvent> watchFleetFixes() => const Stream.empty();

  @override
  Future<Map<String, LiveFix>> fetchLatestFixes() async => const {};

  @override
  Future<LiveOpsSnapshot> getSnapshot() async {
    if (throwOnSnapshot) throw Exception('boom');
    return LiveOpsSnapshot(
      activeTrips: [..._trips],
      incidents: [..._incidents],
      generatedAt: DateTime(2026, 7, 27, 8, 30),
    );
  }

  @override
  Stream<void> watchChanges() => const Stream.empty();

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus next,
    String? note,
  }) async {
    if (throwOnUpdate) throw Exception('cannot update');
    writes.add((id: incidentId, next: next, note: note));

    final index = _incidents.indexWhere((i) => i.id == incidentId);
    if (index == -1) return;
    final current = _incidents[index];
    _incidents[index] = TripIncident(
      id: current.id,
      tripId: current.tripId,
      type: current.type,
      description: current.description,
      status: next,
      createdAt: current.createdAt,
      acknowledgedAt: next == IncidentStatus.acknowledged
          ? DateTime(2026, 7, 27, 8, 30)
          : current.acknowledgedAt,
      resolutionNote: note ?? current.resolutionNote,
    );
  }
}
