import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/trip_history/domain/entities/trip_history_item.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/entities/trip_history_stop.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/repositories/trip_history_repository.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/usecases/get_trip_stops_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/cubit/trip_history_detail_cubit.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/cubit/trip_history_detail_state.dart';

void main() {
  late _FakeTripHistoryRepository repository;
  late TripHistoryDetailCubit cubit;

  setUp(() {
    repository = _FakeTripHistoryRepository();
    cubit = TripHistoryDetailCubit(GetTripStopsUseCase(repository));
  });

  tearDown(() => cubit.close());

  test('load() emits the stops for the requested trip, in order', () async {
    repository.stops = [
      const TripHistoryStop(name: 'محطة أ', order: 1),
      const TripHistoryStop(name: 'محطة ب', order: 2),
    ];

    await cubit.load('trip-1');

    expect(repository.requestedTripId, 'trip-1');
    final state = cubit.state as TripHistoryDetailLoaded;
    expect(state.stops.map((s) => s.name), ['محطة أ', 'محطة ب']);
  });

  test('load() reports an error instead of throwing', () async {
    repository.failure = Exception('تعذر جلب المحطات');

    await cubit.load('trip-1');

    expect(cubit.state, isA<TripHistoryDetailError>());
  });
}

class _FakeTripHistoryRepository implements TripHistoryRepository {
  List<TripHistoryStop> stops = const [];
  Object? failure;
  String? requestedTripId;

  @override
  Future<List<TripHistoryItem>> getTripHistory() async => const [];

  @override
  Future<List<TripHistoryStop>> getTripStops(String tripId) async {
    requestedTripId = tripId;
    if (failure case final error?) throw error;
    return stops;
  }
}
