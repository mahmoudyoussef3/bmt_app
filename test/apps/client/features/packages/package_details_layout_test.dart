import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/packages/domain/entities/my_subscription.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/apps/client/features/packages/domain/repositories/packages_repository.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/filter_packages_usecase.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/get_packages_usecase.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_cubit.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/routes/subscription_arguments.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/screens/subscription_screen.dart';

import '../../client_test_app.dart';

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

PackagePlan _plan() => PackagePlan(
  id: 'p1',
  nameAr: 'باقة الشهر الكامل للعاملين بالقرية الذكية',
  nameEn: 'Full Month Commuter Plan',
  packageType: 'work_month',
  durationDays: 30,
  rideCount: 30,
  price: 3000,
  officeId: 'o1',
  officeName: 'شركة النيل السريع للنقل السياحي',
  officeRating: 4.6,
  officeRatingsCount: 128,
);

Future<PackagesCubit> _openDetails(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  final cubit = PackagesCubit(
    getPackages: GetPackagesUseCase(_FakeRepository([_plan()])),
    filterPackages: const FilterPackagesUseCase(),
  );
  await cubit.load();
  cubit.openDetails(_plan());

  await tester.pumpWidget(
    clientTestApp(
      locale: locale,
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
  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets(
      'the package detail pane lays out cleanly (${locale.languageCode})',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));

        for (final size in const [Size(320, 640), Size(430, 932)]) {
          await tester.binding.setSurfaceSize(size);
          final cubit = await _openDetails(tester, locale: locale);
          expect(tester.takeException(), isNull);

          // Every block down to the terms, so a narrow phone is checked
          // against the whole pane rather than its first screenful.
          await tester.drag(find.byType(ListView), const Offset(0, -1500));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await cubit.close();
        }
      },
    );
  }

  testWidgets('the detail pane quotes no price, and says where one appears', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cubit = await _openDetails(tester);

    // A package is priced per corridor, so the catalogue figure (EGP 3000, or
    // EGP 100 a ride) must never reach a browsing screen — the rider would be
    // quoted a number they will not pay.
    expect(find.textContaining('3000'), findsNothing);
    expect(find.textContaining('3,000'), findsNothing);
    expect(find.textContaining('EGP'), findsNothing);

    // What it says instead: the price is settled once a trip is chosen.
    expect(find.text('Priced on the route you pick'), findsOneWidget);
    expect(find.text('Price shown when you pick a trip'), findsOneWidget);
    expect(find.text('Choose a trip to subscribe'), findsOneWidget);

    await cubit.close();
  });
}
