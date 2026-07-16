import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/trip_history/domain/entities/trip_history_item.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/repositories/trip_history_repository.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/entities/trip_history_stop.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/usecases/get_trip_history_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/cubit/trip_history_cubit.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/cubit/trip_history_state.dart';

void main() {
  late _FakeTripHistoryRepository repository;
  late TripHistoryCubit cubit;

  setUp(() {
    repository = _FakeTripHistoryRepository();
    cubit = TripHistoryCubit(GetTripHistoryUseCase(repository));
  });

  tearDown(() => cubit.close());

  test('load() emits Loading then Loaded with the fetched trips', () async {
    repository.trips = [_trip('a')];

    await cubit.load();

    expect(cubit.state, isA<TripHistoryLoaded>());
    expect((cubit.state as TripHistoryLoaded).trips.map((t) => t.id), ['a']);
  });

  test('load() reports an error without throwing', () async {
    repository.failure = Exception('تعذر الاتصال');

    await cubit.load();

    expect(cubit.state, isA<TripHistoryError>());
  });

  test('refresh() keeps the current list on screen instead of flashing back '
      'to the loading skeleton', () async {
    repository.trips = [_trip('a')];
    await cubit.load();

    // Hold the refetch in flight so the state can be inspected while it's
    // still pending — this is the moment a "refresh flashes to Loading"
    // bug would show up.
    repository.completer = Completer<void>();
    repository.trips = [_trip('a'), _trip('b')];
    final refreshFuture = cubit.refresh();

    expect(cubit.state, isA<TripHistoryLoaded>());
    expect((cubit.state as TripHistoryLoaded).trips.map((t) => t.id), ['a']);

    repository.completer!.complete();
    await refreshFuture;

    expect(cubit.state, isA<TripHistoryLoaded>());
    expect((cubit.state as TripHistoryLoaded).trips.map((t) => t.id), [
      'a',
      'b',
    ]);
  });

  test('refresh() keeps the current list on a silent failure', () async {
    repository.trips = [_trip('a')];
    await cubit.load();

    repository.failure = Exception('انقطع الاتصال');
    await cubit.refresh();

    expect(cubit.state, isA<TripHistoryLoaded>());
    expect((cubit.state as TripHistoryLoaded).trips.map((t) => t.id), ['a']);
  });

  test('refresh() falls back to load() when nothing has loaded yet', () async {
    repository.trips = [_trip('a')];

    await cubit.refresh();

    expect(cubit.state, isA<TripHistoryLoaded>());
  });
}

TripHistoryItem _trip(String id) {
  final departure = DateTime(2026, 7, 16, 8);
  return TripHistoryItem(
    id: id,
    route: 'القاهرة - الإسكندرية',
    tripDate: departure,
    departureTime: departure,
    arrivalTime: departure.add(const Duration(hours: 3)),
    passengerCount: 20,
    boardedCount: 20,
    vehicleNumber: 'BUS-1',
    plateNumber: 'أ ب ج 123',
  );
}

class _FakeTripHistoryRepository implements TripHistoryRepository {
  List<TripHistoryItem> trips = const [];
  Object? failure;

  /// When set, [getTripHistory] waits on it before resolving — lets a test
  /// inspect cubit state while a fetch is still in flight.
  Completer<void>? completer;

  @override
  Future<List<TripHistoryItem>> getTripHistory() async {
    if (completer case final pending?) await pending.future;
    if (failure case final error?) throw error;
    return trips;
  }

  @override
  Future<List<TripHistoryStop>> getTripStops(String tripId) async => const [];
}
