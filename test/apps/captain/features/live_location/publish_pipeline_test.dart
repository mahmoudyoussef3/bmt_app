import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/live_location/domain/entities/location_sharing_state.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/repositories/location_repository.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/usecases/publish_trip_location_usecase.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/usecases/send_location_update_usecase.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/usecases/watch_publishable_location_usecase.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/cubit/live_location_cubit.dart';
import 'package:bmt_app/core/tracking/live_tracking_config.dart';
import 'package:bmt_app/core/tracking/vehicle_fix.dart';

/// The captain's publishing pipeline, end to end:
///
/// ```
/// GPS stream ─▶ validate ─▶ throttle ─▶ publish
///          heartbeat ────────────────▶ publish
/// ```
///
/// What is being protected here is a bill and a battery. Before the pipeline
/// existed the publisher woke the GPS once every 30 s and wrote whatever came
/// back; a stream with no rate limit in front of it would write every fix the
/// sensor produced, which on a moving vehicle is one a second.
void main() {
  const config = LiveTrackingConfig(
    publishInterval: Duration(seconds: 10),
    heartbeatInterval: Duration(seconds: 30),
  );

  late _PipelineRepository repository;
  late LiveLocationCubit cubit;
  late DateTime now;

  setUp(() {
    now = DateTime.utc(2026, 8, 17, 9);
    repository = _PipelineRepository(() => now);
    cubit = LiveLocationCubit(
      sendLocation: SendLocationUpdateUseCase(repository),
      watchPublishableLocation: WatchPublishableLocationUseCase(
        repository,
        config: config,
      ),
      publishLocation: PublishTripLocationUseCase(repository),
      now: () => now,
      config: config,
    );
  });

  tearDown(() => cubit.close());

  /// Drives the GPS at one fix per second for [seconds], advancing both the fake
  /// timer and the clock the fixes are stamped from.
  void driveGps(FakeAsync async, int seconds, {double startLat = 30.0}) {
    for (var i = 0; i < seconds; i++) {
      now = now.add(const Duration(seconds: 1));
      // ~11 m a second: a bus at about 40 km/h.
      repository.emit(
        VehicleFix(
          latitude: startLat + i * 0.0001,
          longitude: 31.0,
          recordedAt: now,
          accuracyMeters: 8,
        ),
      );
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
    }
  }

  group('rate', () {
    test('a minute of once-a-second GPS is six or seven writes, not sixty', () {
      fakeAsync((async) {
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();
        // The immediate leading send on start.
        expect(repository.writes, 1);

        driveGps(async, 60);

        expect(
          repository.writes,
          lessThanOrEqualTo(8),
          reason:
              '60 GPS readings must not be 60 rows, 60 WAL records and 60 '
              'realtime fan-outs to every passenger on the trip',
        );
        expect(
          repository.writes,
          greaterThanOrEqualTo(6),
          reason: 'nor may the feed go quiet while the bus is moving',
        );

        cubit.stopAutoSharing();
      });
    });

    test('the position written is the newest one known, not the oldest', () {
      fakeAsync((async) {
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();
        repository.published.clear();

        driveGps(async, 12, startLat: 31.0);

        // Fixes were stamped 31.0000, 31.0001 … one a second. The first stream
        // fix rides the leading edge; the interesting one is the next write,
        // which the trailing edge must fill with the newest fix seen inside the
        // window rather than the first one that arrived in it.
        expect(repository.published.length, greaterThanOrEqualTo(2));
        expect(
          repository.published.first.latitude,
          31.0,
          reason: 'the leading edge passes the first fix straight through',
        );
        expect(
          repository.published[1].latitude,
          greaterThan(31.0007),
          reason:
              'the trailing edge carries the newest fix in the window, not the '
              'oldest — publishing a position the vehicle has already left is '
              'worse than publishing nothing',
        );

        cubit.stopAutoSharing();
      });
    });
  });

  group('validation', () {
    test('junk never reaches the database', () {
      fakeAsync((async) {
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();
        repository.published.clear();

        // A cold-start (0,0), a fix the device could barely place, and a
        // duplicate of a reading already sent.
        final stamped = now.add(const Duration(seconds: 1));
        repository
          ..emit(VehicleFix(latitude: 0, longitude: 0, recordedAt: stamped))
          ..emit(
            VehicleFix(
              latitude: 30.1,
              longitude: 31.0,
              recordedAt: stamped,
              accuracyMeters: 500,
            ),
          );
        async.elapse(const Duration(seconds: 20));
        async.flushMicrotasks();

        expect(
          repository.published.where(
            (fix) => fix.latitude == 0 || (fix.accuracyMeters ?? 0) > 100,
          ),
          isEmpty,
          reason:
              'a fix every consumer would reject is a write, a WAL row and a '
              'fan-out spent on a position nobody can draw',
        );

        cubit.stopAutoSharing();
      });
    });
  });

  group('the heartbeat', () {
    test('a parked vehicle still proves it is alive', () {
      fakeAsync((async) {
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();
        final afterStart = repository.writes;

        // Standing at a station: the distance filter means the stream says
        // nothing at all, so without the heartbeat the rider could not tell a
        // parked bus from a dead phone.
        async.elapse(const Duration(minutes: 2));
        async.flushMicrotasks();

        expect(
          repository.writes - afterStart,
          4,
          reason: 'two minutes at a 30 s heartbeat is four proofs of life',
        );

        cubit.stopAutoSharing();
      });
    });

    test('a moving vehicle does not pay for it', () {
      fakeAsync((async) {
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();
        repository.acquisitions = 0;

        driveGps(async, 60);

        expect(
          repository.acquisitions,
          0,
          reason:
              'movement already covers every heartbeat window, and waking the '
              'GPS again would spend battery to learn nothing',
        );

        cubit.stopAutoSharing();
      });
    });
  });

  group('lifecycle', () {
    test('stopping releases the GPS subscription', () {
      fakeAsync((async) {
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();
        expect(repository.gpsListeners, 1);

        cubit.stopAutoSharing();
        async.flushMicrotasks();

        expect(
          repository.gpsListeners,
          0,
          reason: 'a stopped publisher must not hold the sensor open',
        );

        repository.published.clear();
        driveGps(async, 30);
        expect(
          repository.published,
          isEmpty,
          reason: 'nor publish anything after it has stopped',
        );
      });
    });

    test('switching trips moves the pipeline, and only one runs', () {
      fakeAsync((async) {
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();
        cubit.startAutoSharing('trip-2');
        async.flushMicrotasks();

        expect(repository.gpsListeners, 1);
        expect(cubit.activeTripId, 'trip-2');

        repository.trips.clear();
        driveGps(async, 20);

        expect(
          repository.trips.toSet(),
          {'trip-2'},
          reason:
              'a captain drives one trip at a time; the previous trip must not '
              'keep publishing positions from a vehicle that has left it',
        );

        cubit.stopAutoSharing();
      });
    });

    test('a rebuilt card does not add a second pipeline', () {
      fakeAsync((async) {
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();
        cubit.startAutoSharing('trip-1');
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();

        expect(
          repository.gpsListeners,
          1,
          reason: 'two subscriptions would mean two sensors and duplicate rows',
        );

        cubit.stopAutoSharing();
      });
    });

    // In real async, not fakeAsync: `close()` completes through the bloc's own
    // internal streams, and awaiting that inside a fake zone deadlocks — the
    // zone is torn down before the future it is waiting on can complete.
    test('closing releases everything', () async {
      cubit.startAutoSharing('trip-1');
      await Future<void>.delayed(Duration.zero);
      expect(repository.gpsListeners, 1);

      await cubit.close();

      expect(
        repository.gpsListeners,
        0,
        reason: 'the sensor subscription goes with the publisher',
      );
      // A leaked heartbeat timer would fail any widget test that mounted the
      // trip-execution page, which is how this class of bug is caught.
    });
  });
}

class _PipelineRepository implements LocationRepository {
  _PipelineRepository(this._now);

  final DateTime Function() _now;
  final _gps = StreamController<VehicleFix>.broadcast();

  /// Every fix that reached the database, in order.
  final List<VehicleFix> published = [];
  final List<String> trips = [];

  /// Writes by either path — the throttled stream or the heartbeat.
  int writes = 0;

  /// Heartbeat/manual acquisitions, which wake the sensor on their own.
  int acquisitions = 0;

  int gpsListeners = 0;

  void emit(VehicleFix fix) => _gps.add(fix);

  @override
  Stream<VehicleFix> watchDevicePosition() {
    gpsListeners++;
    return _gps.stream.transform(
      StreamTransformer<VehicleFix, VehicleFix>.fromHandlers(
        handleData: (fix, sink) => sink.add(fix),
        handleDone: (sink) => sink.close(),
      ),
    ).doOnCancel(() => gpsListeners--);
  }

  @override
  Future<LocationUpdateData> publishFix(String tripId, VehicleFix fix) async {
    writes++;
    published.add(fix);
    trips.add(tripId);
    return LocationUpdateData(
      tripId: tripId,
      latitude: fix.latitude,
      longitude: fix.longitude,
      recordedAt: fix.recordedAt,
    );
  }

  @override
  Future<LocationUpdateData> sendLocation(String tripId) async {
    acquisitions++;
    return publishFix(
      tripId,
      VehicleFix(
        latitude: 30.0444,
        longitude: 31.2357,
        recordedAt: _now(),
        accuracyMeters: 10,
      ),
    );
  }
}

/// `doOnCancel` without pulling rxdart in: the test needs to know when the
/// publisher lets go of the sensor.
extension _OnCancel<T> on Stream<T> {
  Stream<T> doOnCancel(void Function() onCancel) {
    late StreamController<T> controller;
    StreamSubscription<T>? sub;
    controller = StreamController<T>(
      onListen: () => sub = listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      ),
      onCancel: () {
        onCancel();
        final active = sub;
        sub = null;
        return active?.cancel();
      },
    );
    return controller.stream;
  }
}
