import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/routes/domain/entities/route_details.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/route_stop.dart';
import 'package:bmt_app/apps/client/features/routes/domain/repositories/routes_directory_repository.dart';
import 'package:bmt_app/apps/client/features/routes/domain/usecases/get_route_details_usecase.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/route_details_cubit.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/route_details_state.dart';

const _details = RouteDetails(
  id: 'r1',
  name: 'Cairo Express',
  startCity: 'Cairo',
  endCity: 'Alexandria',
  distance: '220 km',
  duration: '3h',
  officeName: 'Nile Express',
  stops: [
    RouteStop(id: 's1', name: 'Ramses Station', order: 1),
    RouteStop(id: 's2', name: 'Mahatet Masr', order: 2),
  ],
);

class _FakeRoutesDirectoryRepository implements RoutesDirectoryRepository {
  _FakeRoutesDirectoryRepository(this.results);

  /// Consumed one per `getRouteDetails()` call — a `null` entry makes that
  /// call throw.
  final List<RouteDetails?> results;
  int calls = 0;

  @override
  Future<RouteDetails> getRouteDetails(String routeId) async {
    final result = results[calls++];
    if (result == null) throw Exception('network down');
    return result;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('RouteDetailsCubit.load', () {
    test('emits RouteDetailsLoaded on success', () async {
      final cubit = RouteDetailsCubit(
        GetRouteDetailsUseCase(_FakeRoutesDirectoryRepository([_details])),
      );
      expect(cubit.state, isA<RouteDetailsLoading>());

      await cubit.load('r1');

      final state = cubit.state;
      expect(state, isA<RouteDetailsLoaded>());
      expect((state as RouteDetailsLoaded).details.name, 'Cairo Express');
      expect(state.details.stops, hasLength(2));
      await cubit.close();
    });

    test('emits RouteDetailsError on failure', () async {
      final cubit = RouteDetailsCubit(
        GetRouteDetailsUseCase(_FakeRoutesDirectoryRepository([null])),
      );

      await cubit.load('r1');

      expect(cubit.state, isA<RouteDetailsError>());
      await cubit.close();
    });

    test('retry after initial failure can still succeed', () async {
      final cubit = RouteDetailsCubit(
        GetRouteDetailsUseCase(
          _FakeRoutesDirectoryRepository([null, _details]),
        ),
      );
      await cubit.load('r1');
      expect(cubit.state, isA<RouteDetailsError>());

      await cubit.load('r1');

      expect(cubit.state, isA<RouteDetailsLoaded>());
      await cubit.close();
    });
  });
}
