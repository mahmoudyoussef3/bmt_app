import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/repositories/captain_trip_repository.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/repositories/seen_trips_repository.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/usecases/get_assigned_trips_usecase.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/usecases/get_seen_trip_ids_usecase.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/usecases/mark_trips_seen_usecase.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/usecases/watch_assigned_trips_usecase.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/presentation/cubit/assigned_trips_cubit.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/presentation/cubit/assigned_trips_state.dart';

void main() {
  late _FakeCaptainTripRepository tripRepository;
  late _FakeSeenTripsRepository seenTripsRepository;
  late AssignedTripsCubit cubit;

  setUp(() {
    tripRepository = _FakeCaptainTripRepository();
    seenTripsRepository = _FakeSeenTripsRepository();
    cubit = AssignedTripsCubit(
      getAssignedTrips: GetAssignedTripsUseCase(tripRepository),
      watchAssignedTrips: WatchAssignedTripsUseCase(tripRepository),
      getSeenTripIds: GetSeenTripIdsUseCase(seenTripsRepository),
      markTripsSeen: MarkTripsSeenUseCase(seenTripsRepository),
    );
  });

  tearDown(() => cubit.close());

  test(
    'load() reports every trip as new when nothing has been seen yet',
    () async {
      tripRepository.trips = [_trip('a'), _trip('b')];

      await cubit.load();

      final state = cubit.state as AssignedTripsLoaded;
      expect(state.newTripIds, {'a', 'b'});
    },
  );

  test(
    'load() excludes trips already marked seen from a prior session',
    () async {
      seenTripsRepository.seenIds = {'a'};
      tripRepository.trips = [_trip('a'), _trip('b')];

      await cubit.load();

      final state = cubit.state as AssignedTripsLoaded;
      expect(state.newTripIds, {'b'});
    },
  );

  test('acknowledgeNewTrips persists every currently-visible trip as seen and '
      'clears the new-trip notice', () async {
    tripRepository.trips = [_trip('a'), _trip('b')];
    await cubit.load();

    await cubit.acknowledgeNewTrips();

    expect(seenTripsRepository.markedSeen, {'a', 'b'});
    final state = cubit.state as AssignedTripsLoaded;
    expect(state.newTripIds, isEmpty);
  });

  test(
    'a trip assigned after acknowledging still shows as new on the next load',
    () async {
      tripRepository.trips = [_trip('a')];
      await cubit.load();
      await cubit.acknowledgeNewTrips();

      tripRepository.trips = [_trip('a'), _trip('c')];
      await cubit.load();

      final state = cubit.state as AssignedTripsLoaded;
      expect(state.newTripIds, {'c'});
    },
  );

  test('refresh() recomputes new-trip ids against the cached seen-set without '
      're-reading storage', () async {
    tripRepository.trips = [_trip('a')];
    await cubit.load();
    await cubit.acknowledgeNewTrips();
    seenTripsRepository.getCallCount = 0;

    tripRepository.trips = [_trip('a'), _trip('d')];
    await cubit.refresh();

    expect(seenTripsRepository.getCallCount, 0);
    final state = cubit.state as AssignedTripsLoaded;
    expect(state.newTripIds, {'d'});
  });
}

AssignedTrip _trip(String id) {
  final departure = DateTime(2026, 7, 16, 8);
  return AssignedTrip(
    id: id,
    route: 'القاهرة - الإسكندرية',
    vehicleNumber: 'BUS-1',
    plateNumber: 'أ ب ج 123',
    departureTime: departure,
    expectedArrivalTime: departure.add(const Duration(hours: 3)),
    stops: const [],
    passengerCount: 10,
    boardedCount: 0,
  );
}

class _FakeCaptainTripRepository implements CaptainTripRepository {
  List<AssignedTrip> trips = const [];

  @override
  Future<List<AssignedTrip>> getAssignedTrips() async => trips;

  @override
  Stream<void> watchTripUpdates() => const Stream.empty();
}

class _FakeSeenTripsRepository implements SeenTripsRepository {
  Set<String> seenIds = const {};
  Set<String>? markedSeen;
  int getCallCount = 0;

  @override
  Future<Set<String>> getSeenTripIds() async {
    getCallCount++;
    return seenIds;
  }

  @override
  Future<void> markSeen(Set<String> tripIds) async {
    markedSeen = tripIds;
    seenIds = tripIds;
  }
}
