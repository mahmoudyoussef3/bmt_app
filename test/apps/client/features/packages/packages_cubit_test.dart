import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/packages/domain/entities/my_subscription.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_filter.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/apps/client/features/packages/domain/repositories/packages_repository.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/filter_packages_usecase.dart';
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

PackagesCubit _cubit(_FakeRepository repo) => PackagesCubit(
  getPackages: GetPackagesUseCase(repo),
  filterPackages: const FilterPackagesUseCase(),
);

void main() {
  group('PackagesCubit load', () {
    test('exposes the whole marketplace and its distinct sellers', () async {
      final cubit = _cubit(_FakeRepository(_catalogue));
      await cubit.load();

      final state = cubit.state as PackagesLoaded;
      expect(state.visiblePackages, hasLength(3));
      expect(state.offices.map((o) => o.id), containsAll(['o1', 'o2']));
      expect(state.hasMultipleOffices, isTrue);
      expect(state.officeFilter, isNull);
      await cubit.close();
    });

    test('a failure surfaces an error state', () async {
      final cubit = _cubit(_FakeRepository(const [], error: Exception('down')));
      await cubit.load();

      expect(cubit.state, isA<PackagesError>());
      await cubit.close();
    });

    test(
      'initialOfficeId opens the marketplace pre-filtered to that seller',
      () async {
        final cubit = _cubit(_FakeRepository(_catalogue));
        await cubit.load(initialOfficeId: 'o2');

        final state = cubit.state as PackagesLoaded;
        expect(state.officeFilter, 'o2');
        expect(state.visiblePackages.map((p) => p.id), ['c']);
        expect(state.selectedOffice?.name, 'Delta Lines');
        await cubit.close();
      },
    );
  });

  group('PackagesCubit office filter', () {
    test('selectOffice narrows the catalogue and can be cleared', () async {
      final cubit = _cubit(_FakeRepository(_catalogue));
      await cubit.load();

      cubit.selectOffice('o1');
      var state = cubit.state as PackagesLoaded;
      expect(state.officeFilter, 'o1');
      expect(state.visiblePackages.map((p) => p.id), ['a', 'b']);

      cubit.selectOffice(null);
      state = cubit.state as PackagesLoaded;
      expect(state.officeFilter, isNull);
      expect(state.visiblePackages, hasLength(3));
      await cubit.close();
    });

    test('duration and office filters compose', () async {
      final cubit = _cubit(_FakeRepository(_catalogue));
      await cubit.load();

      cubit.selectOffice('o1');
      cubit.selectFilter(PackageFilter.monthly);

      final state = cubit.state as PackagesLoaded;
      expect(state.filter, PackageFilter.monthly);
      expect(state.officeFilter, 'o1');
      expect(state.visiblePackages.map((p) => p.id), ['b']);
      await cubit.close();
    });

    test('changing duration keeps the office filter in place', () async {
      final cubit = _cubit(_FakeRepository(_catalogue));
      await cubit.load();

      cubit.selectOffice('o2');
      cubit.selectFilter(PackageFilter.all);

      final state = cubit.state as PackagesLoaded;
      expect(state.officeFilter, 'o2');
      await cubit.close();
    });
  });

  group('PackagesCubit details', () {
    test('openDetails moves to the detail pane for pure discovery', () async {
      final cubit = _cubit(_FakeRepository(_catalogue));
      await cubit.load();

      cubit.openDetails(_catalogue.first);
      final state = cubit.state as PackagesLoaded;
      expect(state.step, SubscriptionStep.details);
      expect(state.selectedPackage?.id, 'a');

      expect(cubit.goBack(), isTrue);
      expect((cubit.state as PackagesLoaded).step, SubscriptionStep.listing);
      await cubit.close();
    });

    test('a single-office catalogue hides the office filter', () async {
      final cubit = _cubit(_FakeRepository([_plan('a', 'o1', 'Nile Express')]));
      await cubit.load();

      expect((cubit.state as PackagesLoaded).hasMultipleOffices, isFalse);
      await cubit.close();
    });
  });
}
