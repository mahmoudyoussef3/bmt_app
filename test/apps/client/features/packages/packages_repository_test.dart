import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/packages/data/datasources/mock_packages_datasource.dart';
import 'package:bmt_app/apps/client/features/packages/data/repositories/packages_repository_impl.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/calculate_package_pricing_usecase.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/filter_packages_usecase.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/get_package_selection_data_usecase.dart';

void main() {
  group('Client packages', () {
    late PackagesRepositoryImpl repository;

    setUp(() {
      repository = const PackagesRepositoryImpl(MockPackagesDatasource());
    });

    test('returns package selection data', () async {
      final data = await GetPackageSelectionDataUseCase(repository)();

      expect(data.packages, hasLength(4));
      expect(data.packages.first.name, 'Weekly Saver');
      expect(data.routes.first, 'Banha - Cairo Express');
      expect(data.vehicles.last.name, 'Premium Luxury');
      expect(data.occupiedSeats, containsAll({3, 7, 12, 16}));
    });

    test('filters package plans by category', () async {
      final data = await GetPackageSelectionDataUseCase(repository)();
      const filterPackages = FilterPackagesUseCase();

      expect(
        filterPackages(packages: data.packages, filter: 'Weekly'),
        hasLength(2),
      );
      expect(
        filterPackages(packages: data.packages, filter: 'Monthly').single.name,
        'Monthly Premium',
      );
      expect(
        filterPackages(
          packages: data.packages,
          filter: 'Quarterly',
        ).single.name,
        'Quarterly Mega',
      );
    });

    test('calculates package pricing for selected seats and vehicle', () async {
      final data = await GetPackageSelectionDataUseCase(repository)();
      const calculatePricing = CalculatePackagePricingUseCase();
      final plan = data.packages[2];
      final vehicle = data.vehicles[1];

      final pricing = calculatePricing(
        package: plan,
        vehicleAddonFee: vehicle.extraFee,
        selectedSeatCount: 2,
      );

      expect(pricing.rawSubtotal, 2460);
      expect(pricing.discountValue, 492);
      expect(pricing.finalPrice, 1968);
      expect(pricing.totalSavings, 1032);
    });
  });
}
