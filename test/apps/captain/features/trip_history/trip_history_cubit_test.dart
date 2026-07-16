import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/trip_history/domain/entities/trip_history_item.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/repositories/trip_history_repository.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/entities/trip_history_stop.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/usecases/get_trip_history_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/cubit/trip_history_cubit.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/cubit/trip_history_state.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/utils/trip_history_filters.dart';

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
    expect(_visibleIds(cubit.state), ['a']);
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
    expect(_visibleIds(cubit.state), ['a']);

    repository.completer!.complete();
    await refreshFuture;

    expect(cubit.state, isA<TripHistoryLoaded>());
    expect(_visibleIds(cubit.state), ['a', 'b']);
  });

  test('refresh() keeps the current list on a silent failure', () async {
    repository.trips = [_trip('a')];
    await cubit.load();

    repository.failure = Exception('انقطع الاتصال');
    await cubit.refresh();

    expect(cubit.state, isA<TripHistoryLoaded>());
    expect(_visibleIds(cubit.state), ['a']);
  });

  test('refresh() falls back to load() when nothing has loaded yet', () async {
    repository.trips = [_trip('a')];

    await cubit.refresh();

    expect(cubit.state, isA<TripHistoryLoaded>());
  });

  test('search() narrows the list to matching routes', () async {
    repository.trips = [
      _trip('a', route: 'القاهرة - الإسكندرية'),
      _trip('b', route: 'القاهرة - أسوان'),
    ];
    await cubit.load();

    cubit.search('أسوان');

    expect(_visibleIds(cubit.state), ['b']);
  });

  test('search() leaves the whole-history totals alone', () async {
    repository.trips = [
      _trip('a', route: 'القاهرة - الإسكندرية'),
      _trip('b', route: 'القاهرة - أسوان'),
    ];
    await cubit.load();

    cubit.search('أسوان');

    // The header reports the trip's real history, not the filtered view.
    final state = cubit.state as TripHistoryLoaded;
    expect(state.totalTrips, 2);
    expect(state.totalPassengers, 40);
  });

  test('an empty search matches everything again', () async {
    repository.trips = [
      _trip('a', route: 'القاهرة - الإسكندرية'),
      _trip('b', route: 'القاهرة - أسوان'),
    ];
    await cubit.load();

    cubit.search('أسوان');
    cubit.search('');

    expect(_visibleIds(cubit.state), ['a', 'b']);
  });

  test('a refresh preserves the active search', () async {
    repository.trips = [
      _trip('a', route: 'القاهرة - الإسكندرية'),
      _trip('b', route: 'القاهرة - أسوان'),
    ];
    await cubit.load();
    cubit.search('أسوان');

    await cubit.refresh();

    // Re-fetching must not silently drop what the captain was looking at.
    final state = cubit.state as TripHistoryLoaded;
    expect(state.query, 'أسوان');
    expect(_visibleIds(cubit.state), ['b']);
  });

  test('filterByDate() reports no matches without claiming the history is '
      'empty', () async {
    repository.trips = [_trip('a', date: DateTime(2020, 1, 1))];
    await cubit.load();

    cubit.filterByDate(TripHistoryDateFilter.today);

    final state = cubit.state as TripHistoryLoaded;
    expect(state.hasNoMatches, isTrue);
    expect(state.hasNoTrips, isFalse);
  });
}

/// The trips the screen would actually render, flattened out of their recency
/// buckets and back into plain order.
List<String> _visibleIds(TripHistoryState state) => [
  for (final group in (state as TripHistoryLoaded).groups)
    for (final trip in group.trips) trip.id,
];

TripHistoryItem _trip(
  String id, {
  String route = 'القاهرة - الإسكندرية',
  DateTime? date,
}) {
  final departure = date ?? DateTime(2026, 7, 16, 8);
  return TripHistoryItem(
    id: id,
    route: route,
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
