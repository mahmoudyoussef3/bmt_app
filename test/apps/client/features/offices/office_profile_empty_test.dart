import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/cubit/office_profile_cubit.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/cubit/office_profile_state.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/screens/office_profile_screen.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_route.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/widgets/office_nothing_listed_view.dart';

import '../../client_test_app.dart';

/// Emits a fixed loaded state; the screen under test only reads the state.
class _StubOfficeProfileCubit extends Cubit<OfficeProfileState>
    implements OfficeProfileCubit {
  _StubOfficeProfileCubit(super.initialState);

  @override
  Future<void> load(String officeId) async {}
}

const _office = OfficeSummary(id: 'o1', name: 'Banha Lines');

Future<void> _pump(WidgetTester tester, OfficeProfileState state) async {
  await tester.binding.setSurfaceSize(const Size(430, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    clientTestApp(
      BlocProvider<OfficeProfileCubit>(
        create: (_) => _StubOfficeProfileCubit(state),
        child: OfficeProfileScreen(office: _office),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an office with nothing published still offers a way onward', (
    tester,
  ) async {
    await _pump(tester, const OfficeProfileLoaded(routes: [], trips: []));

    // Two "none" notes and no action left the rider at the end of the app.
    // Both ways onward must be present and tappable.
    expect(find.byType(OfficeNothingListedView), findsOneWidget);
    expect(find.text('Search all routes'), findsOneWidget);
    expect(find.text('Browse other offices'), findsOneWidget);
  });

  testWidgets('an office with routes but no departures keeps its route list', (
    tester,
  ) async {
    await _pump(
      tester,
      OfficeProfileLoaded(
        routes: [
          OfficeRoute(
            id: 'r1',
            name: 'Banha → Smart Village',
            startCity: 'Banha',
            endCity: 'Smart Village',
          ),
        ],
        trips: const [],
      ),
    );

    expect(find.byType(OfficeNothingListedView), findsNothing);
    // The tile draws the corridor as an origin→destination spine, so the two
    // endpoints are what a rider reads — the route's own name only appears
    // when it says something the cities do not.
    expect(find.text('Banha'), findsWidgets);
    expect(find.text('Smart Village'), findsWidgets);
  });
}
