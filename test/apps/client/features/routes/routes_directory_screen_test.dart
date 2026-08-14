import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/routes/domain/entities/route_details.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/route_stop.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/route_summary.dart';
import 'package:bmt_app/apps/client/features/routes/domain/repositories/routes_directory_repository.dart';
import 'package:bmt_app/apps/client/features/routes/domain/usecases/get_routes_usecase.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/cubit/routes_directory_cubit.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/screens/routes_directory_screen.dart';

import '../../client_test_app.dart';

List<RouteStop> _stops(List<String> names) => [
  for (var i = 0; i < names.length; i++)
    RouteStop(id: 's${i + 1}', name: names[i], order: i + 1),
];

final _catalog = <RouteSummary>[
  RouteSummary(
    id: 'A',
    name: 'Cairo Express',
    startCity: 'Cairo',
    endCity: 'Mansoura',
    officeName: 'Nile Express',
    stops: _stops(['Cairo', 'Banha', 'Tanta', 'Mansoura']),
  ),
  RouteSummary(
    id: 'B',
    name: 'Sharqia Line',
    startCity: 'Cairo',
    endCity: 'Zagazig',
    officeName: 'Delta Lines',
    stops: _stops(['Cairo', 'Shibin', 'Zagazig']),
  ),
];

class _FakeRepository implements RoutesDirectoryRepository {
  const _FakeRepository();

  @override
  Future<List<RouteSummary>> getRoutes() async => _catalog;

  @override
  Future<RouteDetails> getRouteDetails(String routeId) =>
      throw UnimplementedError();
}

Future<List<Object?>> _pumpCatalog(WidgetTester tester) async {
  final opened = <Object?>[];
  final cubit = RoutesDirectoryCubit(const GetRoutesUseCase(_FakeRepository()));
  addTearDown(cubit.close);

  await tester.pumpWidget(
    clientTestApp(
      Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: RoutesDirectoryScreen(
            onOpenRoute: (route, [arguments]) => opened.add(arguments),
          ),
        ),
      ),
    ),
  );
  await cubit.load();
  await tester.pump();
  return opened;
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump();
}

void main() {
  testWidgets('lists every route before anything is searched', (tester) async {
    await _pumpCatalog(tester);

    expect(find.text('Mansoura'), findsOneWidget);
    expect(find.text('Zagazig'), findsOneWidget);
    expect(find.textContaining('Passing through'), findsNothing);
  });

  testWidgets('a station along the way brings its route back, captioned', (
    tester,
  ) async {
    await _pumpCatalog(tester);

    await _search(tester, 'banha');

    expect(find.text('Cairo Express'), findsOneWidget);
    expect(find.text('Passing through Banha'), findsOneWidget);
    expect(find.text('Zagazig'), findsNothing);
  });

  testWidgets('an endpoint search is never captioned as a way point', (
    tester,
  ) async {
    await _pumpCatalog(tester);

    await _search(tester, 'zagazig');

    expect(find.text('Sharqia Line'), findsOneWidget);
    expect(find.textContaining('Passing through'), findsNothing);
  });

  testWidgets('opening a route found through a station opens that route', (
    tester,
  ) async {
    final opened = await _pumpCatalog(tester);

    await _search(tester, 'banha');
    await tester.tap(find.text('Cairo Express'));
    await tester.pump();

    expect(opened, [
      {'routeId': 'A'},
    ]);
  });

  testWidgets('a query matching nothing offers a way back to the catalog', (
    tester,
  ) async {
    await _pumpCatalog(tester);

    await _search(tester, 'aswan');
    expect(find.textContaining('No route matches'), findsOneWidget);

    await tester.tap(find.text('Clear search'));
    await tester.pump();

    expect(find.text('Mansoura'), findsOneWidget);
    expect(find.text('Zagazig'), findsOneWidget);
  });
}
