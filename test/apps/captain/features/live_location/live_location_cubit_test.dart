import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/live_location/domain/entities/location_sharing_state.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/repositories/location_repository.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/usecases/send_location_update_usecase.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/cubit/live_location_cubit.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/cubit/live_location_state.dart';

void main() {
  late _FakeRepository repository;
  late LiveLocationCubit cubit;

  setUp(() {
    repository = _FakeRepository();
    cubit = LiveLocationCubit(
      sendLocation: SendLocationUpdateUseCase(repository),
    );
  });

  test('reports immediately, then once per interval (30s cadence)', () {
    fakeAsync((async) {
      // The platform tracking cadence is 30 seconds (SYSTEM_FLOW.md). Asserted
      // against the constant so the test tracks the contract, not a literal.
      expect(kAutoLocationInterval, const Duration(seconds: 30));

      cubit.startAutoSharing('trip-1');
      async.flushMicrotasks();

      // Immediate: a trip that just departed should not sit unlocated for a
      // full interval before its first fix.
      expect(repository.sendCount, 1);

      async.elapse(kAutoLocationInterval);
      async.flushMicrotasks();
      expect(repository.sendCount, 2);

      async.elapse(kAutoLocationInterval * 3);
      async.flushMicrotasks();
      expect(repository.sendCount, 5);

      cubit.stopAutoSharing();
      async.elapse(kAutoLocationInterval * 10);
      async.flushMicrotasks();
      expect(
        repository.sendCount,
        5,
        reason: 'stopping must actually cancel the timer',
      );
    });
  });

  test('starting twice does not double the reporting rate', () {
    fakeAsync((async) {
      cubit.startAutoSharing('trip-1');
      cubit.startAutoSharing('trip-1');
      async.flushMicrotasks();

      async.elapse(kAutoLocationInterval * 2);
      async.flushMicrotasks();

      // One immediate + two ticks.
      expect(repository.sendCount, 3);
      cubit.stopAutoSharing();
    });
  });

  test(
    'an automatic failure keeps the last good fix on screen and retries',
    () {
      fakeAsync((async) {
        cubit.startAutoSharing('trip-1');
        async.flushMicrotasks();

        final firstFix = (cubit.state as LiveLocationReady).lastSentAt;
        expect(firstFix, isNotNull);

        repository.failNextSend = true;
        async.elapse(kAutoLocationInterval);
        async.flushMicrotasks();

        final afterFailure = cubit.state as LiveLocationReady;
        expect(
          afterFailure.lastSentAt,
          firstFix,
          reason: 'a dropped tick must not erase the position already reported',
        );
        expect(afterFailure.lastError, 'تعذر تحديد الموقع');
        expect(afterFailure.isAutoSharing, isTrue);

        // The next tick recovers on its own — no captain intervention.
        async.elapse(kAutoLocationInterval);
        async.flushMicrotasks();

        final recovered = cubit.state as LiveLocationReady;
        expect(recovered.lastError, isNull);
        expect(recovered.lastSentAt, isNot(firstFix));

        cubit.stopAutoSharing();
      });
    },
  );

  test('a manual send still works while automatic sharing runs', () {
    fakeAsync((async) {
      cubit.startAutoSharing('trip-1');
      async.flushMicrotasks();
      expect(repository.sendCount, 1);

      cubit.send('trip-1');
      async.flushMicrotasks();

      expect(repository.sendCount, 2);
      expect((cubit.state as LiveLocationReady).isAutoSharing, isTrue);

      cubit.stopAutoSharing();
    });
  });

  test('a failed manual send surfaces as an error the captain sees', () {
    fakeAsync((async) {
      repository.failNextSend = true;
      cubit.send('trip-1');
      async.flushMicrotasks();

      final state = cubit.state as LiveLocationError;
      expect(state.message, 'تعذر تحديد الموقع');
    });
  });
}

class _FakeRepository implements LocationRepository {
  int sendCount = 0;
  bool failNextSend = false;

  @override
  Future<LocationUpdateData> sendLocation(String tripId) async {
    sendCount++;
    if (failNextSend) {
      failNextSend = false;
      throw Exception('تعذر تحديد الموقع');
    }
    return LocationUpdateData(
      tripId: tripId,
      latitude: 30.0 + sendCount / 1000,
      longitude: 31.0,
      recordedAt: DateTime.now(),
    );
  }
}
