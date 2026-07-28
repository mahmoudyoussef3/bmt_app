import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/live_location/domain/entities/location_sharing_state.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/repositories/location_repository.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/usecases/send_location_update_usecase.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/cubit/live_location_cubit.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/cubit/live_location_state.dart';

/// The publisher's ownership rules.
///
/// `LiveLocationCubit` is registered as a singleton, which is what lets position
/// reporting outlive the screen that started it. That is the whole point, and it
/// is also what makes these rules load-bearing: with one shared publisher and
/// several widgets able to reach it, "who may stop it" and "can a second one
/// start" stop being incidental and become the difference between a client's map
/// that keeps moving and one that silently freezes mid-journey.
void main() {
  late _RecordingRepository repository;
  late LiveLocationCubit cubit;

  /// `fakeAsync` advances timers but not the wall clock, so the publisher's
  /// clock is driven explicitly and kept in step with `async.elapse`. The fake
  /// repository stamps its fixes from the same clock, which is what makes
  /// "how old is the last landed fix" mean anything here.
  late DateTime now;

  setUp(() {
    now = DateTime.utc(2026, 7, 29, 8);
    repository = _RecordingRepository(() => now);
    cubit = LiveLocationCubit(
      sendLocation: SendLocationUpdateUseCase(repository),
      now: () => now,
    );
  });

  tearDown(() => cubit.close());

  group('one publisher', () {
    test('a rebuilt card re-starting the same trip does not add a timer', () {
      fakeAsync((async) {
        // Every rebuild of the trip-execution page calls `startAutoSharing`
        // again. If that ever meant a second timer, the vehicle would report
        // twice per interval: two GPS acquisitions, two inserts, double the
        // battery cost, and duplicate fixes for the client map to reconcile.
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();
        cubit.startAutoSharing('trip-1');
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();

        expect(repository.sends, 1, reason: 'one immediate fix, not three');

        async.elapse(kAutoLocationInterval);
        async.flushMicrotasks();
        expect(repository.sends, 2, reason: 'one fix per interval, not three');

        cubit.stopAutoSharing();
      });
    });

    test('switching trips reports the new one and abandons the old', () {
      fakeAsync((async) {
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();
        cubit.startAutoSharing('trip-2');
        async.flushMicrotasks();

        expect(cubit.activeTripId, 'trip-2');

        repository.trips.clear();
        async.elapse(kAutoLocationInterval * 2);
        async.flushMicrotasks();

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
  });

  group('who may stop it', () {
    test('a card for a finished trip cannot silence a running one', () {
      fakeAsync((async) {
        cubit.startAutoSharing('trip-2');
        async.flushMicrotasks();

        // The trip-execution page for trip-1 finishes and its card syncs
        // `enabled: false`. With a shared publisher and an unnamed stop, that
        // would take trip-2 — the trip actually being driven — off the air.
        cubit.stopAutoSharing(tripId: 'trip-1');

        expect(cubit.isAutoSharing, isTrue);
        expect(cubit.activeTripId, 'trip-2');

        final before = repository.sends;
        async.elapse(kAutoLocationInterval);
        async.flushMicrotasks();
        expect(repository.sends, before + 1);

        cubit.stopAutoSharing();
      });
    });

    test('the trip it names, and an unnamed stop, both stop it', () {
      fakeAsync((async) {
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();
        cubit.stopAutoSharing(tripId: 'trip-1');
        expect(cubit.isAutoSharing, isFalse);

        // Unnamed is what sign-out uses: stop whatever is running, whoever it
        // belongs to.
        cubit.startAutoSharing('trip-9');
        async.flushMicrotasks();
        cubit.stopAutoSharing();
        expect(cubit.isAutoSharing, isFalse);
        expect(cubit.activeTripId, isNull);

        final before = repository.sends;
        async.elapse(kAutoLocationInterval * 3);
        async.flushMicrotasks();
        expect(
          repository.sends,
          before,
          reason: 'a stopped publisher is silent',
        );
      });
    });
  });

  group('coming back from the background', () {
    test('closes the gap immediately rather than waiting out the interval', () {
      fakeAsync((async) {
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();

        // The captain took a call. `fakeAsync` cannot suspend a timer the way
        // iOS does, so the gap is reproduced by its only observable trace:
        // ticks that produce no landed fix, leaving `lastSentAt` two minutes
        // behind. A suspended app and an app that cannot reach the server look
        // exactly like this, and the publisher treats them the same.
        repository.failing = true;
        now = now.add(const Duration(minutes: 2));
        async.elapse(const Duration(minutes: 2));
        async.flushMicrotasks();
        repository.failing = false;

        final before = repository.sends;
        cubit.resumeIfStale();
        async.flushMicrotasks();

        expect(
          repository.sends,
          before + 1,
          reason: 'a resumed app publishes at once, not up to 30 s later',
        );

        cubit.stopAutoSharing();
      });
    });

    test('a quick app-switch does not cost an extra GPS acquisition', () {
      fakeAsync((async) {
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();

        now = now.add(const Duration(seconds: 3));
        async.elapse(const Duration(seconds: 3));
        final before = repository.sends;

        cubit.resumeIfStale();
        async.flushMicrotasks();

        expect(
          repository.sends,
          before,
          reason:
              'the last fix is still fresh; waking the GPS again would spend '
              'battery to learn nothing',
        );

        cubit.stopAutoSharing();
      });
    });

    test('a resume with nothing running stays silent', () {
      fakeAsync((async) {
        cubit.resumeIfStale();
        async.flushMicrotasks();
        expect(repository.sends, 0);
      });
    });
  });

  group('telling the captain the truth', () {
    test('counts the run of failures, and any success clears it', () {
      fakeAsync((async) {
        repository.failing = true;
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();
        async.elapse(kAutoLocationInterval * 2);
        async.flushMicrotasks();

        final failed = cubit.state as LiveLocationReady;
        expect(
          failed.consecutiveFailures,
          3,
          reason:
              'three sends have not landed — the client map has been frozen '
              'for a minute and a half, and that is a different fact from one '
              'dropped tick',
        );

        repository.failing = false;
        async.elapse(kAutoLocationInterval);
        async.flushMicrotasks();

        final recovered = cubit.state as LiveLocationReady;
        expect(recovered.consecutiveFailures, 0);
        expect(recovered.lastError, isNull);
        expect(recovered.lastSentAt, isNotNull);

        cubit.stopAutoSharing();
      });
    });
  });
}

class _RecordingRepository implements LocationRepository {
  _RecordingRepository(this._now);

  final DateTime Function() _now;
  int sends = 0;
  bool failing = false;
  final List<String> trips = [];

  @override
  Future<LocationUpdateData> sendLocation(String tripId) async {
    if (failing) throw Exception('لا يوجد اتصال بالإنترنت');
    sends++;
    trips.add(tripId);
    return LocationUpdateData(
      tripId: tripId,
      latitude: 30.0444,
      longitude: 31.2357,
      recordedAt: _now(),
    );
  }
}
