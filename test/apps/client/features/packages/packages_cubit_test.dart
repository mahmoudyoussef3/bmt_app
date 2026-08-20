import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/packages/domain/entities/my_subscription.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/apps/client/features/packages/domain/repositories/packages_repository.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/get_trip_packages_usecase.dart';
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

  String? requestedOfficeId;
  Set<String>? requestedPackageIds;

  @override
  Future<List<PackagePlan>> getTripPackages({
    required String officeId,
    required Set<String> packageIds,
  }) async {
    requestedOfficeId = officeId;
    requestedPackageIds = packageIds;
    if (error != null) throw error!;
    return packages
        .where((p) => p.officeId == officeId && packageIds.contains(p.id))
        .toList();
  }

  @override
  Future<List<PackagePlan>> getOfficePackages(String officeId) async =>
      packages.where((p) => p.officeId == officeId).toList();

  @override
  Future<MySubscription?> getMySubscription() async => null;
}

PackagesCubit _cubit(_FakeRepository repo) =>
    PackagesCubit(getTripPackages: GetTripPackagesUseCase(repo));

void main() {
  group('PackagesCubit loadForTrip', () {
    test('asks for the trip\'s own menu, not the whole catalogue', () async {
      final repo = _FakeRepository(_catalogue);
      final cubit = _cubit(repo);
      await cubit.loadForTrip(officeId: 'o1', packageIds: {'a', 'b'});

      expect(repo.requestedOfficeId, 'o1');
      expect(repo.requestedPackageIds, {'a', 'b'});
      final state = cubit.state as PackagesLoaded;
      expect(state.packages.map((p) => p.id), ['a', 'b']);
      await cubit.close();
    });

    test('another office\'s package never reaches the wizard', () async {
      final cubit = _cubit(_FakeRepository(_catalogue));
      await cubit.loadForTrip(officeId: 'o1', packageIds: {'a', 'c'});

      final state = cubit.state as PackagesLoaded;
      expect(state.packages.map((p) => p.id), ['a']);
      await cubit.close();
    });

    test('a failure surfaces an error state', () async {
      final cubit = _cubit(_FakeRepository(const [], error: Exception('down')));
      await cubit.loadForTrip(officeId: 'o1', packageIds: const {'a'});

      expect(cubit.state, isA<PackagesError>());
      await cubit.close();
    });
  });
}
