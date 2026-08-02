import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/packages/domain/entities/my_subscription.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/apps/client/features/packages/domain/repositories/packages_repository.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/get_packages_usecase.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_cubit.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_state.dart';

PackagePlan _plan(
  String id,
  String officeId,
  String officeName, {
  int days = 30,
}) => PackagePlan(
  id: id,
  nameAr: 'باقة $id',
  nameEn: 'Package $id',
  packageType: 'work_month',
  durationDays: days,
  rideCount: 30,
  price: 3000,
  officeId: officeId,
  officeName: officeName,
  officeRating: 4.5,
  officeRatingsCount: 10,
);

final _catalogue = [
  _plan('a', 'o1', 'Nile Express', days: 7),
  _plan('b', 'o1', 'Nile Express', days: 30),
  _plan('c', 'o2', 'Delta Lines', days: 30),
];

class _FakeRepository implements PackagesRepository {
  _FakeRepository(this.packages, {this.error});

  final List<PackagePlan> packages;
  final Object? error;

  @override
  Future<List<PackagePlan>> getPackages() async {
    if (error != null) throw error!;
    return packages;
  }

  @override
  Future<List<PackagePlan>> getOfficePackages(String officeId) async =>
      packages.where((p) => p.officeId == officeId).toList();

  @override
  Future<MySubscription?> getMySubscription() async => null;
}

PackagesCubit _cubit(_FakeRepository repo) =>
    PackagesCubit(getPackages: GetPackagesUseCase(repo));

void main() {
  group('PackagesCubit load', () {
    test('exposes every plan on offer for the wizard to price', () async {
      final cubit = _cubit(_FakeRepository(_catalogue));
      await cubit.load();

      final state = cubit.state as PackagesLoaded;
      expect(state.packages.map((p) => p.id), ['a', 'b', 'c']);
      await cubit.close();
    });

    test('a failure surfaces an error state', () async {
      final cubit = _cubit(_FakeRepository(const [], error: Exception('down')));
      await cubit.load();

      expect(cubit.state, isA<PackagesError>());
      await cubit.close();
    });
  });
}
