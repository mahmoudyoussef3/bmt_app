import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/packages/data/datasources/mock_packages_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/packages/data/repositories/packages_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/packages/domain/entities/package_pricing.dart';
import 'package:bmt_app/apps/dashboard/features/packages/domain/usecases/packages_usecases.dart';

void main() {
  group('Packages pricing clean architecture chain', () {
    test(
      'loads package plans and route points without exposing coordinates to UI',
      () async {
        final repository = PackagesRepositoryImpl(MockPackagesDatasource());
        final getPlans = GetPackagePlansUseCase(repository);
        final getRoutes = GetPackageRoutesUseCase(repository);

        final plans = await getPlans();
        final routes = await getRoutes();

        expect(plans, hasLength(5));
        expect(
          plans.map((plan) => plan.packageType),
          contains(PackageType.monthly),
        );
        expect(routes.first.points.first.name, 'بنها');
        expect(routes.first.points.first.latitude, isNonZero);
      },
    );

    test('updates and toggles package plans locally', () async {
      final repository = PackagesRepositoryImpl(MockPackagesDatasource());
      final getPlans = GetPackagePlansUseCase(repository);
      final updatePlan = UpdatePackagePlanUseCase(repository);
      final togglePlan = TogglePackagePlanStatusUseCase(repository);

      final plan = (await getPlans()).first;
      final updated = await updatePlan(plan.copyWith(price: 130));
      expect(updated.price, 130);

      final toggled = await togglePlan(updated.id);
      expect(toggled.isActive, isFalse);
    });

    test('assigns price to valid route point segment', () async {
      final repository = PackagesRepositoryImpl(MockPackagesDatasource());
      final getPlans = GetPackagePlansUseCase(repository);
      final getRoutes = GetPackageRoutesUseCase(repository);
      final assignPrice = AssignPackagePriceToRoutePointsUseCase(repository);

      final plan = (await getPlans()).first;
      final route = (await getRoutes()).first;
      final created = await assignPrice(
        RoutePackagePriceEntity(
          id: '',
          routeId: route.id,
          routeName: route.name,
          fromPointId: route.points.first.id,
          fromPointName: route.points.first.name,
          toPointId: route.points.last.id,
          toPointName: route.points.last.name,
          packagePlanId: plan.id,
          packageName: plan.nameAr,
          price: 120,
          currency: 'ج.م',
          isActive: true,
        ),
      );

      expect(created.id, isNotEmpty);
      expect(created.fromPointName, 'بنها');
      expect(created.toPointName, 'التجمع الخامس');
    });

    test('rejects invalid route point order and zero price', () async {
      final repository = PackagesRepositoryImpl(MockPackagesDatasource());
      final getPlans = GetPackagePlansUseCase(repository);
      final getRoutes = GetPackageRoutesUseCase(repository);
      final assignPrice = AssignPackagePriceToRoutePointsUseCase(repository);

      final plan = (await getPlans()).first;
      final route = (await getRoutes()).first;
      expect(
        () => assignPrice(
          RoutePackagePriceEntity(
            id: '',
            routeId: route.id,
            routeName: route.name,
            fromPointId: route.points.last.id,
            fromPointName: route.points.last.name,
            toPointId: route.points.first.id,
            toPointName: route.points.first.name,
            packagePlanId: plan.id,
            packageName: plan.nameAr,
            price: 0,
            currency: 'ج.م',
            isActive: true,
          ),
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('تعذر حفظ السعر'),
          ),
        ),
      );
    });
  });
}
