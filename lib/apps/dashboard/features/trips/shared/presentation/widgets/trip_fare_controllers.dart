import 'package:flutter/material.dart';

import 'package:bmt_app/core/pricing/package_tier_pricing.dart';

import '../../domain/entities/trip_pricing.dart';

/// Owns the five fare text fields (base + four package tiers) and the rule
/// that keeps the tiers in sync with the base fare.
///
/// Shared by trip creation and trip-pricing editing so a fare is configured
/// in exactly ONE way: type the ticket price, and the package tiers derive
/// themselves. Editing a tier by hand pins it (the base stops overwriting it).
class TripFareControllers {
  TripFareControllers();

  final oneTime = TextEditingController();
  final _tiers = {
    for (final tier in PackageTierPricing.tiers)
      tier.key: TextEditingController(),
  };

  /// Set once the operator hand-edits any tier, so we stop auto-deriving and
  /// silently overwriting their intent.
  bool _tiersEdited = false;

  TextEditingController tierController(PackageTier tier) => _tiers[tier.key]!;

  double get baseFare => parseFare(oneTime.text);

  double tierValue(PackageTier tier) => parseFare(tierController(tier).text);

  /// The configured tier totals, keyed by [PackageTier.key], ready to hand to
  /// `CreateTripInput.packageTierPrices`.
  Map<String, double> get tierPrices => {
    for (final tier in PackageTierPricing.tiers) tier.key: tierValue(tier),
  };

  void markTiersEdited() => _tiersEdited = true;

  /// Recompute every tier from the base fare, unless the operator has taken
  /// manual control of the tiers.
  void syncTiersFromBase({bool force = false}) {
    if (_tiersEdited && !force) return;
    final base = baseFare;
    for (final tier in PackageTierPricing.tiers) {
      final price = PackageTierPricing.priceFor(tier, base);
      tierController(tier).text = price <= 0 ? '' : formatFare(price);
    }
  }

  /// Seed the fields from an existing `trip_pricing` row (the edit path).
  /// Tiers that already diverge from the derived defaults are treated as
  /// hand-set so we don't clobber them on the next base-fare keystroke.
  void loadFrom(TripPricing pricing) {
    oneTime.text = formatFare(pricing.oneTimePrice);
    _tiers['five_days']!.text = formatFare(pricing.fiveDaysPrice);
    _tiers['ten_days']!.text = formatFare(pricing.tenDaysPrice);
    _tiers['monthly']!.text = formatFare(pricing.monthlyPrice);
    _tiers['three_months']!.text = formatFare(pricing.threeMonthsPrice);
    _tiersEdited = !_matchesDerivedTiers(pricing.oneTimePrice);
  }

  bool _matchesDerivedTiers(double base) {
    for (final tier in PackageTierPricing.tiers) {
      final derived = PackageTierPricing.priceFor(tier, base);
      if ((tierValue(tier) - derived).abs() > 0.01) return false;
    }
    return true;
  }

  /// True once the fare is usable: a positive base and positive tiers.
  bool get isValid {
    if (baseFare <= 0) return false;
    return PackageTierPricing.tiers.every((tier) => tierValue(tier) > 0);
  }

  /// Apply the current fares onto [pricing], which carries the stop pair.
  TripPricing applyTo(TripPricing pricing) {
    return pricing.copyWith(
      oneTimePrice: baseFare,
      fiveDaysPrice: tierValue(PackageTierPricing.fiveDays),
      tenDaysPrice: tierValue(PackageTierPricing.tenDays),
      monthlyPrice: tierValue(PackageTierPricing.monthly),
      threeMonthsPrice: tierValue(PackageTierPricing.threeMonths),
    );
  }

  void clear() {
    oneTime.clear();
    for (final controller in _tiers.values) {
      controller.clear();
    }
    _tiersEdited = false;
  }

  void dispose() {
    oneTime.dispose();
    for (final controller in _tiers.values) {
      controller.dispose();
    }
  }

  /// Accepts Arabic-Indic digits and a comma decimal separator, both of which
  /// `double.tryParse` rejects outright (silently collapsing the fare to 0).
  static double parseFare(String value) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    final buffer = StringBuffer();
    for (final rune in value.trim().runes) {
      final char = String.fromCharCode(rune);
      final arabicIndex = arabic.indexOf(char);
      buffer.write(arabicIndex >= 0 ? '$arabicIndex' : char);
    }
    return double.tryParse(buffer.toString().replaceAll(',', '.')) ?? 0;
  }

  static String formatFare(double value) {
    if (value <= 0) return '';
    final rounded = value.round();
    return value == rounded ? '$rounded' : value.toStringAsFixed(2);
  }
}
