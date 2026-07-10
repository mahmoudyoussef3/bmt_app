import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/routes/domain/entities/routes_hub_data.dart';
import 'package:bmt_app/apps/client/features/routes/domain/repositories/routes_hub_repository.dart';
import 'package:bmt_app/apps/client/features/routes/domain/usecases/get_routes_hub_data_usecase.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_hub_cubit.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_hub_state.dart';

class _FakeRoutesHubRepository implements RoutesHubRepository {
  _FakeRoutesHubRepository({required this.results});

  /// Consumed one per call — a `null` entry makes that call throw.
  final List<RoutesHubData?> results;
  int calls = 0;

  @override
  Future<RoutesHubData> getRoutesHubData() async {
    final result = results[calls++];
    if (result == null) throw Exception('network down');
    return result;
  }
}

const _routesHubData = RoutesHubData(
  title: 'Go anywhere',
  subtitle: 'Book a route in seconds',
  searchTitle: 'Search',
  searchDescription: 'Find your trip',
  searchAction: RoutesHubAction(route: '/search'),
  popularRoutesAction: RoutesHubAction(route: '/popular'),
  flowSteps: [],
);

RoutesHubCubit _cubit(List<RoutesHubData?> results) => RoutesHubCubit(
  GetRoutesHubDataUseCase(_FakeRoutesHubRepository(results: results)),
);

void main() {
  group('RoutesHubCubit.load', () {
    test('initial load emits RoutesHubLoaded on success', () async {
      final cubit = _cubit([_routesHubData]);
      expect(cubit.state, isA<RoutesHubLoading>());

      await cubit.load();

      final state = cubit.state;
      expect(state, isA<RoutesHubLoaded>());
      expect((state as RoutesHubLoaded).data.title, 'Go anywhere');
      expect(state.refreshFailure, isNull);
    });

    test('initial load emits RoutesHubError on failure', () async {
      final cubit = _cubit([null]);

      await cubit.load();

      expect(cubit.state, isA<RoutesHubError>());
    });

    test('refresh keeps loaded content instead of flashing the skeleton',
        () async {
      final cubit = _cubit([_routesHubData, _routesHubData]);
      await cubit.load();

      final emitted = <RoutesHubState>[];
      final subscription = cubit.stream.listen(emitted.add);
      await cubit.load();
      await subscription.cancel();

      expect(emitted.whereType<RoutesHubLoading>(), isEmpty);
      expect(cubit.state, isA<RoutesHubLoaded>());
    });

    test('failed refresh keeps content and reports the failure', () async {
      final cubit = _cubit([_routesHubData, null]);
      await cubit.load();

      await cubit.load();

      final state = cubit.state;
      expect(state, isA<RoutesHubLoaded>());
      expect((state as RoutesHubLoaded).data.title, 'Go anywhere');
      expect(state.refreshFailure, isNotNull);
    });

    test('retry after initial failure can still succeed', () async {
      final cubit = _cubit([null, _routesHubData]);
      await cubit.load();
      expect(cubit.state, isA<RoutesHubError>());

      await cubit.load();

      expect(cubit.state, isA<RoutesHubLoaded>());
    });
  });
}
