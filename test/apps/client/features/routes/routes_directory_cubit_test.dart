import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/routes/domain/entities/route_stop.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/route_summary.dart';
import 'package:bmt_app/apps/client/features/routes/domain/repositories/routes_directory_repository.dart';
import 'package:bmt_app/apps/client/features/routes/domain/usecases/get_routes_usecase.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_directory_cubit.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_directory_state.dart';

List<RouteStop> _stops(List<String> names) => [
  for (var i = 0; i < names.length; i++)
    RouteStop(id: 's${i + 1}', name: names[i], order: i + 1),
];

final _routes = <RouteSummary>[
  RouteSummary(
    id: 'r1',
    name: 'Cairo Express',
    startCity: 'Cairo',
    endCity: 'Alexandria',
    officeName: 'Nile Express',
    stops: _stops(['Cairo', 'Banha', 'Tanta', 'Alexandria']),
  ),
  RouteSummary(
    id: 'r2',
    name: 'Delta Line',
    startCity: 'Tanta',
    endCity: 'Mansoura',
    officeName: 'Delta Lines',
    stops: _stops(['Tanta', 'Mahalla', 'Mansoura']),
  ),
  RouteSummary(
    id: 'r3',
    name: 'Red Sea Line',
    startCity: 'Cairo',
    endCity: 'Hurghada',
    officeName: 'Red Sea Travel',
  ),
];

class _FakeRoutesDirectoryRepository implements RoutesDirectoryRepository {
  _FakeRoutesDirectoryRepository(this.results);

  /// Consumed one per `getRoutes()` call — a `null` entry makes that call
  /// throw.
  final List<List<RouteSummary>?> results;
  int calls = 0;

  @override
  Future<List<RouteSummary>> getRoutes() async {
    final result = results[calls++];
    if (result == null) throw Exception('network down');
    return result;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RoutesDirectoryCubit _cubit([List<RouteSummary>? routes]) {
  return RoutesDirectoryCubit(
    GetRoutesUseCase(_FakeRoutesDirectoryRepository([routes ?? _routes])),
  );
}

void main() {
  group('RoutesDirectoryLoaded filtering', () {
    test('an empty query lists every route', () {
      final state = RoutesDirectoryLoaded(_routes);

      expect(state.visibleRoutes, hasLength(3));
      expect(state.isFilteredEmpty, isFalse);
    });

    test('matches a route by name, case-insensitively', () {
      final state = RoutesDirectoryLoaded(_routes, query: 'delta');

      expect(state.visibleRoutes.single.name, 'Delta Line');
    });

    test('matches a route by an endpoint city', () {
      final state = RoutesDirectoryLoaded(_routes, query: 'hurghada');

      expect(state.visibleRoutes.single.name, 'Red Sea Line');
    });

    test('matches a route by its operating office', () {
      final state = RoutesDirectoryLoaded(_routes, query: 'nile express');

      expect(state.visibleRoutes.single.name, 'Cairo Express');
    });

    test('matches a route by a station it only passes through', () {
      final state = RoutesDirectoryLoaded(_routes, query: 'banha');

      expect(state.visibleRoutes.single.name, 'Cairo Express');
      expect(state.visibleMatches.single.viaStop, 'Banha');
    });

    test(
      'a query matching nothing is distinguishable from an empty catalog',
      () {
        final searched = RoutesDirectoryLoaded(_routes, query: 'zzz');
        final empty = RoutesDirectoryLoaded(const <RouteSummary>[]);

        expect(searched.isFilteredEmpty, isTrue);
        expect(empty.isFilteredEmpty, isFalse);
      },
    );
  });

  group('RoutesDirectoryCubit.load', () {
    test('initial load emits RoutesDirectoryLoaded on success', () async {
      final cubit = _cubit();
      expect(cubit.state, isA<RoutesDirectoryLoading>());

      await cubit.load();

      final state = cubit.state;
      expect(state, isA<RoutesDirectoryLoaded>());
      expect((state as RoutesDirectoryLoaded).routes, hasLength(3));
      await cubit.close();
    });

    test('initial load emits RoutesDirectoryError on failure', () async {
      final cubit = RoutesDirectoryCubit(
        GetRoutesUseCase(_FakeRoutesDirectoryRepository([null])),
      );

      await cubit.load();

      expect(cubit.state, isA<RoutesDirectoryError>());
      await cubit.close();
    });
  });

  group('RoutesDirectoryCubit.setQuery', () {
    test('does nothing before the catalog has loaded', () {
      final cubit = _cubit();
      cubit.setQuery('delta');

      expect(cubit.state, isA<RoutesDirectoryLoading>());
    });

    test('narrows the loaded catalog to a station along the way', () async {
      final cubit = _cubit();
      await cubit.load();

      cubit.setQuery('banha');

      final state = cubit.state as RoutesDirectoryLoaded;
      expect(state.visibleRoutes.single.id, 'r1');
      await cubit.close();
    });

    test('clearing the query restores the whole catalog', () async {
      final cubit = _cubit();
      await cubit.load();
      cubit.setQuery('banha');

      cubit.setQuery('');

      final state = cubit.state as RoutesDirectoryLoaded;
      expect(state.visibleRoutes, hasLength(3));
      await cubit.close();
    });
  });

  group('RoutesDirectoryCubit.refresh', () {
    test('keeps the rider’s query applied', () async {
      final repository = _FakeRoutesDirectoryRepository([_routes, _routes]);
      final cubit = RoutesDirectoryCubit(GetRoutesUseCase(repository));
      await cubit.load();
      cubit.setQuery('delta');

      await cubit.refresh();

      final state = cubit.state as RoutesDirectoryLoaded;
      expect(state.query, 'delta');
      expect(state.visibleRoutes.single.name, 'Delta Line');
      await cubit.close();
    });

    test('a failed refresh keeps the last usable list', () async {
      final repository = _FakeRoutesDirectoryRepository([_routes, null]);
      final cubit = RoutesDirectoryCubit(GetRoutesUseCase(repository));
      await cubit.load();

      await cubit.refresh();

      final state = cubit.state;
      expect(state, isA<RoutesDirectoryLoaded>());
      expect((state as RoutesDirectoryLoaded).routes, hasLength(3));
      await cubit.close();
    });
  });
}
