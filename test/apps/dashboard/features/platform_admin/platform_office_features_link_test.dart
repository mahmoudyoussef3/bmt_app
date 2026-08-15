import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/entities/platform_analytics.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/entities/platform_office.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/presentation/cubit/platform_admin_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/presentation/cubit/platform_admin_state.dart';
import 'package:bmt_app/apps/dashboard/features/platform_admin/presentation/screens/platform_offices_screen.dart';

/// «مكاتب المنصة» answers *is this office real, and should passengers see it*.
/// What the office is allowed to **use** lives one module across, in التراخيص,
/// and before this hand-off existed the only route between them was the sidebar
/// plus finding the same office a second time.
///
/// The link is optional on purpose: the screen must still render in a harness
/// that has no way to switch modules.
class _FakeAdminCubit extends Cubit<PlatformAdminState>
    implements PlatformAdminCubit {
  _FakeAdminCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

const _office = PlatformOffice(
  id: 'office-a',
  name: 'مكتب الإسكندرية',
  slug: 'alex-office',
  description: 'نقل يومي',
  serviceAreas: ['الإسكندرية'],
  status: 'active',
  listingStatus: 'listed',
  rating: 0,
  ratingsCount: 0,
  operators: 1,
  drivers: 0,
  routes: 0,
);

Future<List<String>> _pump(WidgetTester tester, {required bool linked}) async {
  final opened = <String>[];
  // Wide: the filter bar's own dropdowns overflow below ~1700 in a bare
  // harness, which is a pre-existing layout of that widget and not what this
  // test is about.
  tester.view.physicalSize = const Size(1800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: DashboardAppTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider<PlatformAdminCubit>.value(
          // Analytics resolved rather than null: the overview panel animates
          // its placeholder while the numbers are in flight, and this test is
          // about the card underneath it.
          value: _FakeAdminCubit(
            const PlatformAdminLoaded([
              _office,
            ], analytics: PlatformAnalytics.empty),
          ),
          child: Scaffold(
            body: PlatformOfficesScreen(
              onOpenFeatures: linked ? opened.add : null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  testWidgets('an office card opens its feature board by id', (tester) async {
    final opened = await _pump(tester, linked: true);

    await tester.tap(find.text('الميزات والحدود'));
    await tester.pumpAndSettle();

    expect(opened, ['office-a']);
  });

  testWidgets('without a destination the card simply omits the action', (
    tester,
  ) async {
    await _pump(tester, linked: false);

    expect(find.text('الميزات والحدود'), findsNothing);
    expect(
      find.text('مكتب الإسكندرية'),
      findsOneWidget,
      reason: 'the rest of the card is unaffected',
    );
  });
}
