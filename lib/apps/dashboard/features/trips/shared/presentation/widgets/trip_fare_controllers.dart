import 'package:flutter/material.dart';

import 'package:bmt_app/core/pricing/package_tier_pricing.dart';

import '../../domain/entities/trip_pricable_package.dart';
import '../../domain/entities/trip_pricing.dart';

/// Owns the fare text fields — the base ticket price plus one field per the
/// office's own multi-ride packages — and the rule that keeps the package
/// fields in sync with the base fare.
///
/// Shared by trip creation and trip-pricing editing so a fare is configured
/// in exactly ONE way: type the ticket price, and every package's suggested
/// price derives itself from [PackageTierPricing]. Editing a package's price
/// by hand pins it (the base stops overwriting it).
class TripFareControllers {
  TripFareControllers(this.packages)
    : _packagePrices = {
        for (final package in packages) package.id: TextEditingController(),
      };

  /// The office's own pricable packages, in display order. Fixed for the
  /// lifetime of these controllers — the trip planner/editor fetches this
  /// list once before building the fare form.
  final List<TripPricablePackage> packages;

  final oneTime = TextEditingController();
  final Map<String, TextEditingController> _packagePrices;

  /// Set once the operator hand-edits any package price, so we stop
  /// auto-deriving and silently overwriting their intent.
  bool _pricesEdited = false;

  TextEditingController controllerFor(TripPricablePackage package) =>
      _packagePrices[package.id]!;

  double get baseFare => parseFare(oneTime.text);

  double priceFor(TripPricablePackage package) =>
      parseFare(controllerFor(package).text);

  /// The configured package prices, keyed by package id, ready to hand to
  /// `CreateTripInput.packagePrices` / `TripPricing.packagePrices`. A
  /// package left blank (0) is omitted rather than saved as a zero price.
  Map<String, double> get packagePrices => {
    for (final package in packages)
      if (priceFor(package) > 0) package.id: priceFor(package),
  };

  void markPricesEdited() => _pricesEdited = true;

  /// Recompute every package's suggested price from the base fare, unless
  /// the operator has taken manual control of the prices.
  void syncPricesFromBase({bool force = false}) {
    if (_pricesEdited && !force) return;
    final base = baseFare;
    for (final package in packages) {
      final price = PackageTierPricing.priceForRideCount(
        package.rideCount,
        base,
      );
      controllerFor(package).text = price <= 0 ? '' : formatFare(price);
    }
  }

  /// Seed the fields from an existing `trip_pricing` row (the edit path).
  /// Packages that already diverge from the derived defaults are treated as
  /// hand-set so we don't clobber them on the next base-fare keystroke.
  void loadFrom(TripPricing pricing) {
    oneTime.text = formatFare(pricing.oneTimePrice);
    for (final package in packages) {
      final price = pricing.packagePrices[package.id] ?? 0;
      controllerFor(package).text = formatFare(price);
    }
    _pricesEdited = !_matchesDerivedPrices(pricing.oneTimePrice);
  }

  bool _matchesDerivedPrices(double base) {
    for (final package in packages) {
      final derived = PackageTierPricing.priceForRideCount(
        package.rideCount,
        base,
      );
      if ((priceFor(package) - derived).abs() > 0.01) return false;
    }
    return true;
  }

  /// True once the fare is usable: a positive base price. Package prices are
  /// each optional (an office may not have priced every package on every
  /// stop pair yet).
  bool get isValid => baseFare > 0;

  /// Apply the current fares onto [pricing], which carries the stop pair.
  TripPricing applyTo(TripPricing pricing) {
    return pricing.copyWith(
      oneTimePrice: baseFare,
      packagePrices: packagePrices,
    );
  }

  void clear() {
    oneTime.clear();
    for (final controller in _packagePrices.values) {
      controller.clear();
    }
    _pricesEdited = false;
  }

  void dispose() {
    oneTime.dispose();
    for (final controller in _packagePrices.values) {
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
