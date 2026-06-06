import 'dart:math' as math;

import '../entities/package_plan.dart';

class CalculatePackagePricingUseCase {
  const CalculatePackagePricingUseCase();

  PackagePricing call({
    required PackagePlan? package,
    required int vehicleAddonFee,
    required int selectedSeatCount,
  }) {
    final seatMultiplier = math.max(1, selectedSeatCount);
    final packageCost = package?.startingPrice ?? 0;
    final rawSubtotal = (packageCost + vehicleAddonFee) * seatMultiplier;
    final discountValue =
        ((rawSubtotal * (package?.discountPercent ?? 0)) / 100).round();
    final finalPrice = rawSubtotal - discountValue;
    final totalSavings =
        ((package?.savingsAmount ?? 0) * seatMultiplier) + discountValue;

    return PackagePricing(
      rawSubtotal: rawSubtotal,
      discountValue: discountValue,
      finalPrice: finalPrice,
      totalSavings: totalSavings,
    );
  }
}
