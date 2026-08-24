import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/apps/client/features/offices/domain/repositories/offices_repository.dart';
import 'package:bmt_app/apps/client/features/offices/domain/usecases/get_offices_usecase.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/cubit/offices_directory_cubit.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/cubit/offices_directory_state.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/screens/offices_directory_screen.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/widgets/office_card.dart';

import '../../client_test_app.dart';

const _offices = <OfficeSummary>[
  OfficeSummary(
    id: 'o1',
    name: 'Nile Express',
    serviceAreas: ['Cairo', 'Alexandria'],
  ),
  OfficeSummary(id: 'o2', name: 'Delta Lines', serviceAreas: ['Tanta']),
  OfficeSummary(id: 'o3', name: 'Red Sea Travel', serviceAreas: ['Hurghada']),
];

class _FakeOfficesRepository implements OfficesRepository {
  _FakeOfficesRepository(this.offices);

  final List<OfficeSummary> offices;

  @override
  Future<List<OfficeSummary>> getOffices() async => offices;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

OfficesDirectoryCubit _cubit([List<OfficeSummary> offices = _offices]) {
  return OfficesDirectoryCubit(
    GetOfficesUseCase(_FakeOfficesRepository(offices)),
  );
}

Future<void> _pump(WidgetTester tester, OfficesDirectoryCubit cubit) async {
  // A real phone height, not the default 800x600 test surface: the office
  // card carries a full photo banner now, so the default surface's cache
  // extent no longer builds all three cards without a taller viewport.
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(430, 932));

  await tester.pumpWidget(
    clientTestApp(
      BlocProvider<OfficesDirectoryCubit>.value(
        value: cubit,
        child: const OfficesDirectoryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('OfficesDirectoryLoaded filtering', () {
    test('an empty query lists every office', () {
      const state = OfficesDirectoryLoaded(_offices);

      expect(state.visibleOffices, hasLength(3));
      expect(state.isFilteredEmpty, isFalse);
    });

    test('matches an office by name, case-insensitively', () {
      const state = OfficesDirectoryLoaded(_offices, query: 'nile');

      expect(state.visibleOffices.single.name, 'Nile Express');
    });

    test('matches an office by a city it serves', () {
      // A rider looking for a way to Alexandria searches the city, not the
      // name of a company they have never heard of.
      const state = OfficesDirectoryLoaded(_offices, query: 'Alexandria');

      expect(state.visibleOffices.single.name, 'Nile Express');
    });

    test('a query matching nothing is distinguishable from an empty directory', () {
      const searched = OfficesDirectoryLoaded(_offices, query: 'zzz');
      const empty = OfficesDirectoryLoaded(<OfficeSummary>[]);

      expect(searched.isFilteredEmpty, isTrue);
      expect(empty.isFilteredEmpty, isFalse);
    });
  });

  group('OfficesDirectoryCubit', () {
    test('setQuery does nothing before the directory has loaded', () {
      final cubit = _cubit();
      cubit.setQuery('nile');

      expect(cubit.state, isA<OfficesDirectoryLoading>());
    });

    test('a refresh keeps the rider’s query applied', () async {
      final cubit = _cubit();
      await cubit.load();
      cubit.setQuery('delta');

      await cubit.refresh();

      final state = cubit.state as OfficesDirectoryLoaded;
      expect(state.query, 'delta');
      expect(state.visibleOffices.single.name, 'Delta Lines');
      await cubit.close();
    });
  });

  group('OfficesDirectoryScreen', () {
    testWidgets('typing narrows the list to matching offices', (tester) async {
      final cubit = _cubit();
      await cubit.load();
      await _pump(tester, cubit);

      expect(find.byType(OfficeCard), findsNWidgets(3));

      await tester.enterText(find.byType(TextField), 'red sea');
      await tester.pumpAndSettle();

      expect(find.byType(OfficeCard), findsOneWidget);
      expect(find.text('Red Sea Travel'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('clearing a no-match search also empties the search box', (
      tester,
    ) async {
      final cubit = _cubit();
      await cubit.load();
      await _pump(tester, cubit);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.byType(OfficeCard), findsNothing);

      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();

      expect(find.byType(OfficeCard), findsNWidgets(3));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty,
        reason: 'the box must not keep showing a query that no longer applies',
      );
      await cubit.close();
    });

    testWidgets('an empty directory offers no search box at all', (
      tester,
    ) async {
      final cubit = _cubit(const <OfficeSummary>[]);
      await cubit.load();
      await _pump(tester, cubit);

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(OfficeCard), findsNothing);
      await cubit.close();
    });
  });
}
