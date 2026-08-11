import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_passenger.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/entities/passenger.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/repositories/passenger_manifest_repository.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/usecases/get_trip_passengers_usecase.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/usecases/update_passenger_status_usecase.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/usecases/watch_trip_passengers_usecase.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/cubit/passenger_manifest_cubit.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/cubit/passenger_manifest_state.dart';

void main() {
  late _FakeRepository repository;
  late PassengerManifestCubit cubit;

  setUp(() {
    repository = _FakeRepository();
    cubit = PassengerManifestCubit(
      getTripPassengers: GetTripPassengersUseCase(repository),
      watchTripPassengers: WatchTripPassengersUseCase(repository),
      updatePassengerStatus: UpdatePassengerStatusUseCase(repository),
    );
  });

  tearDown(() => cubit.close());

  test('a failed status write does not lock out later ones', () async {
    await cubit.load('trip-1');

    repository.failNextUpdate = true;
    await cubit.updateStatus(
      tripPassengerId: 'p1',
      status: PassengerBoardingStatus.boarded,
    );

    // The failure is reported over a manifest that is still on screen...
    expect(cubit.state, isA<PassengerManifestUpdateError>());

    // ...and the captain can immediately try the next passenger. Guarding on
    // the concrete loaded type here used to swallow this call entirely,
    // freezing the boarding door after a single dropped request.
    await cubit.updateStatus(
      tripPassengerId: 'p2',
      status: PassengerBoardingStatus.boarded,
    );

    expect(repository.updates, ['p1:boarded-failed', 'p2:boarded']);
    final state = cubit.state as PassengerManifestLoaded;
    expect(
      state.visiblePassengers.firstWhere((p) => p.id == 'p2').status,
      PassengerBoardingStatus.boarded,
    );
  });

  test('a failed write rolls the optimistic change back', () async {
    await cubit.load('trip-1');
    repository.failNextUpdate = true;

    await cubit.updateStatus(
      tripPassengerId: 'p1',
      status: PassengerBoardingStatus.absent,
    );

    final state = cubit.state as PassengerManifestUpdateError;
    expect(
      state.loaded.visiblePassengers.firstWhere((p) => p.id == 'p1').status,
      PassengerBoardingStatus.pending,
      reason: 'the card must not keep showing a status the server rejected',
    );
    expect(state.message, isNot(startsWith('Exception')));
  });

  test('boarding progress is measured against expected passengers, so a '
      'cancelled booking cannot hold the trip below 100%', () async {
    repository.passengers = [
      _passenger('p1', PassengerBoardingStatus.boarded),
      _passenger('p2', PassengerBoardingStatus.boarded),
      _passenger('p3', PassengerBoardingStatus.cancelled),
    ];

    await cubit.load('trip-1');

    final counts = (cubit.state as PassengerManifestLoaded).counts;
    expect(counts.total, 3);
    expect(counts.expected, 2);
    expect(counts.boardedRatio, 1.0);
  });

  test('filters and search survive a realtime refresh', () async {
    await cubit.load('trip-1');
    cubit.toggleStatusFilter(PassengerBoardingStatus.pending);
    cubit.search('سارة');

    repository.emitChange();
    await Future<void>.delayed(Duration.zero);

    final state = cubit.state as PassengerManifestLoaded;
    expect(state.statusFilter, PassengerBoardingStatus.pending);
    expect(state.search, 'سارة');
    expect(state.visiblePassengers.map((p) => p.id), ['p2']);
  });
}

Passenger _passenger(String id, PassengerBoardingStatus status) {
  return Passenger(
    id: id,
    name: id == 'p2' ? 'سارة أحمد' : 'محمد علي',
    seat: 'A1',
    pickupPoint: 'محطة مصر',
    destination: 'سيدي جابر',
    pickupTime: '08:00',
    phone: '01000000000',
    status: status,
  );
}

class _FakeRepository implements PassengerManifestRepository {
  List<Passenger> passengers = [
    _passenger('p1', PassengerBoardingStatus.pending),
    _passenger('p2', PassengerBoardingStatus.pending),
  ];

  final List<String> updates = [];
  bool failNextUpdate = false;
  final _changes = StreamController<void>.broadcast();

  void emitChange() => _changes.add(null);

  @override
  Future<List<Passenger>> getTripPassengers(String tripId) async => passengers;

  @override
  Stream<void> watchPassengerUpdates(String tripId) => _changes.stream;

  @override
  Future<void> updatePassengerStatus({
    required String tripPassengerId,
    required PassengerBoardingStatus status,
    NoShowReason? noShowReason,
    String? note,
  }) async {
    if (failNextUpdate) {
      failNextUpdate = false;
      updates.add('$tripPassengerId:${status.name}-failed');
      throw Exception('تعذر الاتصال بالخادم');
    }
    updates.add('$tripPassengerId:${status.name}');
    passengers = [
      for (final p in passengers)
        if (p.id == tripPassengerId) p.copyWith(status: status) else p,
    ];
  }
}
