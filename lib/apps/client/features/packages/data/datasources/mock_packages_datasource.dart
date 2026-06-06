import '../models/package_plan_model.dart';

class MockPackagesDatasource {
  const MockPackagesDatasource();

  Future<PackageSelectionDataModel> getSelectionData() async {
    return const PackageSelectionDataModel(
      packages: [
        PackagePlanModel(
          name: 'Weekly Saver',
          durationLabel: '7 Days',
          days: 7,
          tripsCount: 10,
          discountPercent: 10,
          startingPrice: 270,
          savingsAmount: 30,
          description:
              'Ideal for short-term commutes and temporary travel needs.',
        ),
        PackagePlanModel(
          name: 'Bi-Weekly Smart',
          durationLabel: '14 Days',
          days: 14,
          tripsCount: 20,
          discountPercent: 15,
          startingPrice: 510,
          savingsAmount: 90,
          description:
              'Great balance of cost and flexibility for mid-term projects.',
        ),
        PackagePlanModel(
          name: 'Monthly Premium',
          durationLabel: '30 Days',
          days: 30,
          tripsCount: 44,
          discountPercent: 20,
          startingPrice: 1080,
          savingsAmount: 270,
          description:
              'Our most popular plan. Lock in your daily commute and seats.',
        ),
        PackagePlanModel(
          name: 'Quarterly Mega',
          durationLabel: '90 Days',
          days: 90,
          tripsCount: 132,
          discountPercent: 25,
          startingPrice: 2970,
          savingsAmount: 990,
          description:
              'Ultimate savings for regular commuters who want zero hassle.',
        ),
      ],
      routes: [
        'Banha - Cairo Express',
        'Alexandria - Cairo Highway',
        'Suez Daily Commute',
      ],
      pickupPoints: ['Banha Station', 'Banha Downtown', 'Cairo Toll Gate'],
      destinations: ['Smart Village', 'Nasr City', 'Heliopolis'],
      vehicles: [
        PackageVehicleTypeModel(
          name: 'Standard Coach',
          iconKey: 'bus',
          extraFee: 0,
          description: 'Comfortable standard AC travel.',
        ),
        PackageVehicleTypeModel(
          name: 'Comfort Van',
          iconKey: 'van',
          extraFee: 150,
          description: 'Faster executive mini-vans.',
        ),
        PackageVehicleTypeModel(
          name: 'Premium Luxury',
          iconKey: 'car',
          extraFee: 300,
          description: 'VIP premium seating and priority route.',
        ),
      ],
      occupiedSeats: {3, 7, 12, 16},
    );
  }
}
