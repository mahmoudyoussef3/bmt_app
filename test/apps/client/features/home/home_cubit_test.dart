import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/domain/repositories/home_repository.dart';
import 'package:bmt_app/apps/client/features/home/domain/usecases/get_home_data_usecase.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_cubit.dart';
import 'package:bmt_app/apps/client/features/home/presentation/cubit/home_state.dart';

class _FakeHomeRepository implements HomeRepository {
  _FakeHomeRepository({required this.results});

  /// Consumed one per call — a `null` entry makes that call throw.
  final List<HomeData?> results;
  int calls = 0;

  @override
  Future<HomeData> getHomeData() async {
    final result = results[calls++];
    if (result == null) throw Exception('network down');
    return result;
  }
}

const _homeData = HomeData(
  popularRoutes: [],
  nearbyTrips: [],
  packagePlans: [],
  pickupSuggestions: [],
  destinationSuggestions: ['Downtown'],
  timeSuggestions: [],
  userName: 'Mahmoud',
);

HomeCubit _cubit(List<HomeData?> results) =>
    HomeCubit(GetHomeDataUseCase(_FakeHomeRepository(results: results)));

void main() {
  group('HomeCubit.load', () {
    test('initial load emits HomeLoaded on success', () async {
      final cubit = _cubit([_homeData]);
      expect(cubit.state, isA<HomeLoading>());

      await cubit.load();

      final state = cubit.state;
      expect(state, isA<HomeLoaded>());
      expect((state as HomeLoaded).data.userName, 'Mahmoud');
      expect(state.refreshFailure, isNull);
    });

    test('initial load emits HomeError on failure', () async {
      final cubit = _cubit([null]);

      await cubit.load();

      expect(cubit.state, isA<HomeError>());
    });

    test('refresh keeps loaded content instead of flashing the skeleton',
        () async {
      final cubit = _cubit([_homeData, _homeData]);
      await cubit.load();

      final emitted = <HomeState>[];
      final subscription = cubit.stream.listen(emitted.add);
      await cubit.load();
      await subscription.cancel();

      expect(emitted.whereType<HomeLoading>(), isEmpty);
      expect(cubit.state, isA<HomeLoaded>());
    });

    test('failed refresh keeps content and reports the failure', () async {
      final cubit = _cubit([_homeData, null]);
      await cubit.load();

      await cubit.load();

      final state = cubit.state;
      expect(state, isA<HomeLoaded>());
      expect((state as HomeLoaded).data.userName, 'Mahmoud');
      expect(state.refreshFailure, isNotNull);
    });

    test('retry after initial failure can still succeed', () async {
      final cubit = _cubit([null, _homeData]);
      await cubit.load();
      expect(cubit.state, isA<HomeError>());

      await cubit.load();

      expect(cubit.state, isA<HomeLoaded>());
    });
  });
}
