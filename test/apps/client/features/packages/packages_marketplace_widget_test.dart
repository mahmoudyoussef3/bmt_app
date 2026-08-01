import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/offices/presentation/routes/offices_routes.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/my_subscription.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/apps/client/features/packages/domain/repositories/packages_repository.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/filter_packages_usecase.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/get_packages_usecase.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_cubit.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/routes/subscription_arguments.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/screens/subscription_screen.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/widgets/listing/package_card.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/widgets/listing/packages_office_filter_bar.dart';

import '../../client_test_app.dart';

PackagePlan _plan(
  String id, {
  String officeId = 'o1',
  String officeName = 'Nile Express',
  double officeRating = 4.6,
  int officeRatingsCount = 30,
}) => PackagePlan(
  id: id,
  nameAr: 'باقة $id',
  nameEn: 'Package $id',
  packageType: 'work_month',
  durationDays: 30,
  rideCount: 30,
  price: 3000,
  officeId: officeId,
  officeName: officeName,
  officeRating: officeRating,
  officeRatingsCount: officeRatingsCount,
);

class _FakeRepository implements PackagesRepository {
  _FakeRepository(this.packages);

  final List<PackagePlan> packages;

  @override
  Future<List<PackagePlan>> getPackages() async => packages;

  @override
  Future<List<PackagePlan>> getOfficePackages(String officeId) async =>
      packages.where((p) => p.officeId == officeId).toList();

  @override
  Future<MySubscription?> getMySubscription() async => null;
}

Future<PackagesCubit> _pump(
  WidgetTester tester,
  List<PackagePlan> packages, {
  Locale locale = const Locale('en'),
}) async {
  final cubit = PackagesCubit(
    getPackages: GetPackagesUseCase(_FakeRepository(packages)),
    filterPackages: const FilterPackagesUseCase(),
  );
  await cubit.load();

  await tester.pumpWidget(
    clientTestApp(
      locale: locale,
      routes: {
        OfficesRoutes.profile: (_) =>
            const Scaffold(body: Text('OFFICE PROFILE')),
      },
      BlocProvider<PackagesCubit>.value(
        value: cubit,
        child: const SubscriptionScreen(arguments: SubscriptionArguments()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

void main() {
  testWidgets('a package card wears its provider office identity', (
    tester,
  ) async {
    final cubit = await _pump(tester, [_plan('a')]);

    expect(find.text('Nile Express'), findsWidgets);
    expect(find.byType(PackageCard), findsOneWidget);

    await cubit.close();
  });

  testWidgets('the office filter appears only for a multi-office marketplace', (
    tester,
  ) async {
    final cubit = await _pump(tester, [
      _plan('a', officeId: 'o1', officeName: 'Nile Express'),
      _plan('b', officeId: 'o2', officeName: 'Delta Lines'),
    ]);

    final bar = tester.widget<PackagesOfficeFilterBar>(
      find.byType(PackagesOfficeFilterBar),
    );
    // The widget is always in the tree but renders nothing for one office; with
    // two, its "all offices" affordance is visible.
    expect(bar, isNotNull);
    expect(find.text('All offices'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('a single-office marketplace shows no office filter chrome', (
    tester,
  ) async {
    final cubit = await _pump(tester, [_plan('a'), _plan('b')]);

    expect(find.text('All offices'), findsNothing);

    await cubit.close();
  });

  testWidgets('a package routes through to its provider office profile', (
    tester,
  ) async {
    final cubit = await _pump(tester, [_plan('a')]);

    await tester.tap(find.byType(PackageCard));
    await tester.pumpAndSettle();

    // Detail pane names the seller and offers the way in. The provider block
    // sits below the plan header and the pricing note, so it is scrolled to
    // rather than assumed on-screen.
    await tester.scrollUntilVisible(find.text('View office'), 120);
    await tester.pumpAndSettle();
    expect(find.text('View office'), findsOneWidget);

    await tester.tap(find.text('View office'));
    await tester.pumpAndSettle();

    expect(find.text('OFFICE PROFILE'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('an empty marketplace explains itself and offers a way out', (
    tester,
  ) async {
    final cubit = await _pump(tester, const []);

    expect(find.text('No packages available yet'), findsOneWidget);
    expect(find.text('Explore available trips'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('filtering to an office with none offers a way back to all', (
    tester,
  ) async {
    final cubit = await _pump(tester, [
      _plan('a', officeId: 'o1', officeName: 'Nile Express'),
      _plan('b', officeId: 'o2', officeName: 'Delta Lines'),
    ]);

    // Filter to an office that has no packages in the catalogue.
    cubit.selectOffice('o404');
    await tester.pumpAndSettle();

    expect(find.text('No packages from this office yet'), findsOneWidget);
    expect(find.text('View all offices'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('renders long Arabic names on a narrow screen without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = await _pump(tester, [
      _plan(
        'a',
        officeId: 'o1',
        officeName: 'شركة النيل السريع للنقل السياحي والرحلات بين المحافظات',
      ),
      _plan(
        'b',
        officeId: 'o2',
        officeName: 'مؤسسة الدلتا الحديثة لخدمات النقل الجماعي المكيّف',
      ),
    ], locale: const Locale('ar'));

    expect(tester.takeException(), isNull);
    expect(find.byType(PackageCard), findsNWidgets(2));

    await cubit.close();
  });
}
