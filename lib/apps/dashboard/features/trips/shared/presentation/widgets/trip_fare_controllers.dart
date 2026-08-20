import 'package:flutter/material.dart';

import 'package:bmt_app/core/pricing/package_tier_pricing.dart';

import '../../domain/entities/trip_package_offer.dart';
import '../../domain/entities/trip_pricable_package.dart';
import '../../domain/entities/trip_pricing.dart';

/// One package on the trip's menu, as the fare editor holds it: which package
/// it is (or that it does not exist yet), what it costs on this trip, and the
/// operator's note about it.
class TripFarePackageEntry {
  TripFarePackageEntry._({
    required this.packageId,
    required this.isTripScoped,
    required String name,
    required int rideCount,
    required int durationDays,
  }) : name = TextEditingController(text: name),
       rides = TextEditingController(text: rideCount > 0 ? '$rideCount' : ''),
       days = TextEditingController(
         text: durationDays > 0 ? '$durationDays' : '',
       );

  /// A package the office already has — from its catalog, or created for this
  /// trip on an earlier pass. Its shape belongs to the package row, so only
  /// the price and the note are editable here.
  factory TripFarePackageEntry.existing(TripPricablePackage package) {
    return TripFarePackageEntry._(
      packageId: package.id,
      isTripScoped: package.isTripScoped,
      name: package.name,
      rideCount: package.rideCount,
      durationDays: package.durationDays,
    );
  }

  /// A package the operator is writing for this trip and nothing else. Fully
  /// editable, and created in `transport_packages` (with `trip_id`) only when
  /// the trip is saved.
  factory TripFarePackageEntry.blank() {
    return TripFarePackageEntry._(
      packageId: '',
      isTripScoped: true,
      name: '',
      rideCount: 0,
      durationDays: 0,
    );
  }

  /// `transport_packages.id`, empty while the package still has to be created.
  final String packageId;
  final bool isTripScoped;

  final TextEditingController name;
  final TextEditingController rides;
  final TextEditingController days;
  final price = TextEditingController();
  final note = TextEditingController();

  /// Set once the operator types this package's price by hand, so the base
  /// ticket price stops re-deriving it underneath them.
  bool priceEdited = false;

  /// True while the package has yet to be created — the only case in which
  /// its name, ride count and duration may be typed. Editing those on an
  /// existing package would change the office's catalog, not this trip.
  bool get isDraft => packageId.trim().isEmpty;

  int get rideCount => TripFareControllers.parseCount(rides.text);
  int get durationDays => TripFareControllers.parseCount(days.text);
  double get priceValue => TripFareControllers.parseFare(price.text);

  TripPackageOffer toOffer() => TripPackageOffer(
    packageId: packageId,
    name: name.text.trim(),
    rideCount: rideCount,
    durationDays: durationDays,
    price: priceValue,
    note: note.text.trim(),
    isTripScoped: isTripScoped,
  );

  void dispose() {
    name.dispose();
    rides.dispose();
    days.dispose();
    price.dispose();
    note.dispose();
  }
}

/// Owns the fare form — the base ticket price plus the package menu this trip
/// sells — and the rule that keeps a package's suggested price in step with
/// the base fare until the operator overrides it.
///
/// Shared by trip creation and trip-pricing editing so a fare is configured in
/// exactly ONE way. The menu itself is the office's to build: [catalog]
/// packages can be added or left out, and [addBlank] writes a package that
/// exists on this trip alone (see `20260820100000_trip_scoped_packages.sql`).
class TripFareControllers {
  TripFareControllers(this.catalog);

  /// Every package the editor may put on this trip: the office's saved
  /// catalog templates, plus — in the trip pricing tab — the packages already
  /// created for this trip.
  final List<TripPricablePackage> catalog;

  /// The trip's package menu, in display order.
  final List<TripFarePackageEntry> entries = [];

  final oneTime = TextEditingController();

  TextEditingController get baseFareController => oneTime;

  double get baseFare => parseFare(oneTime.text);

  /// Catalog packages not already on the menu — what the "add from catalog"
  /// picker offers.
  List<TripPricablePackage> get unusedCatalog => catalog
      .where((package) => !entries.any((e) => e.packageId == package.id))
      .toList();

  /// Seeds the menu with the office's catalog packages, priced from the base
  /// fare. The planner starts here so an office that just wants its usual
  /// packages types one number — but every entry is removable, and nothing
  /// forces a catalog package onto a trip.
  void seedFromCatalog() {
    for (final package in catalog) {
      entries.add(TripFarePackageEntry.existing(package));
    }
    syncPricesFromBase();
  }

  void addFromCatalog(TripPricablePackage package) {
    if (entries.any((e) => e.packageId == package.id)) return;
    final entry = TripFarePackageEntry.existing(package);
    entries.add(entry);
    _applyDerivedPrice(entry);
  }

  /// Adds an empty row for a package the operator will write themselves.
  TripFarePackageEntry addBlank() {
    final entry = TripFarePackageEntry.blank();
    entries.add(entry);
    return entry;
  }

  /// Swaps a just-created package into the menu in place of the draft row
  /// that described it, keeping the price and note the operator typed. Used
  /// by the pricing editor, which must create a written package before the
  /// pricing row can reference it.
  void adoptCreatedPackage(TripFarePackageEntry draft, String packageId) {
    final index = entries.indexOf(draft);
    if (index < 0) return;
    final adopted =
        TripFarePackageEntry.existing(
            TripPricablePackage(
              id: packageId,
              name: draft.name.text.trim(),
              rideCount: draft.rideCount,
              durationDays: draft.durationDays,
              isTripScoped: true,
            ),
          )
          ..price.text = draft.price.text
          ..note.text = draft.note.text
          ..priceEdited = true;
    entries[index] = adopted;
    draft.dispose();
  }

  void removeAt(int index) {
    if (index < 0 || index >= entries.length) return;
    entries.removeAt(index).dispose();
  }

  /// This trip's package prices, keyed by `transport_packages.id`, ready for
  /// `TripPricing.packagePrices`. Entries still awaiting creation have no id
  /// yet and are carried by [offers] instead.
  Map<String, double> get packagePrices => {
    for (final entry in entries)
      if (!entry.isDraft && entry.priceValue > 0)
        entry.packageId: entry.priceValue,
  };

  /// The same menu's notes, keyed the same way. A blank note is omitted
  /// rather than stored as an empty string.
  Map<String, String> get packageNotes => {
    for (final entry in entries)
      if (!entry.isDraft &&
          entry.priceValue > 0 &&
          entry.note.text.trim().isNotEmpty)
        entry.packageId: entry.note.text.trim(),
  };

  /// The whole menu as domain offers, including packages that still have to
  /// be created. This is what trip creation hands [CreateTripUseCase].
  List<TripPackageOffer> get offers => [
    for (final entry in entries)
      if (entry.toOffer().isSellable) entry.toOffer(),
  ];

  /// True once at least one entry is incomplete — named but unpriced, or
  /// priced but unnamed. Lets the form say what is missing instead of
  /// silently dropping the row on save.
  bool get hasIncompletePackage => entries.any((entry) {
    final offer = entry.toOffer();
    final touched =
        offer.name.isNotEmpty ||
        offer.price > 0 ||
        offer.rideCount > 0 ||
        offer.durationDays > 0;
    return touched && !offer.isSellable;
  });

  void markPriceEdited(TripFarePackageEntry entry) => entry.priceEdited = true;

  /// Recompute the suggested price of every package the operator has not
  /// priced by hand, from the base fare.
  void syncPricesFromBase() {
    for (final entry in entries) {
      if (entry.priceEdited) continue;
      _applyDerivedPrice(entry);
    }
  }

  void _applyDerivedPrice(TripFarePackageEntry entry) {
    if (entry.priceEdited) return;
    final price = PackageTierPricing.priceForRideCount(
      entry.rideCount,
      baseFare,
    );
    entry.price.text = price <= 0 ? '' : formatFare(price);
  }

  /// Seeds the form from an existing `trip_pricing` row (the edit path): the
  /// pair's ticket price, and one entry per package this pair actually
  /// prices. A package the office has but never priced on this pair is left
  /// off the menu rather than shown at zero — it is simply not sold here.
  void loadFrom(TripPricing pricing) {
    oneTime.text = formatFare(pricing.oneTimePrice);
    for (final entry in entries) {
      entry.dispose();
    }
    entries.clear();
    for (final package in catalog) {
      final price = pricing.packagePrices[package.id];
      if (price == null || price <= 0) continue;
      final entry = TripFarePackageEntry.existing(package)
        ..price.text = formatFare(price)
        ..note.text = pricing.packageNotes[package.id] ?? ''
        ..priceEdited = true;
      entries.add(entry);
    }
  }

  /// True once the fare is usable: a positive base price, and no half-filled
  /// package row. Package prices themselves are optional — a trip may sell
  /// single rides only.
  bool get isValid => baseFare > 0 && !hasIncompletePackage;

  /// Apply the current fares onto [pricing], which carries the stop pair.
  TripPricing applyTo(TripPricing pricing) {
    return pricing.copyWith(
      oneTimePrice: baseFare,
      packagePrices: packagePrices,
      packageNotes: packageNotes,
    );
  }

  void clear() {
    oneTime.clear();
    for (final entry in entries) {
      entry.dispose();
    }
    entries.clear();
  }

  void dispose() {
    oneTime.dispose();
    for (final entry in entries) {
      entry.dispose();
    }
    entries.clear();
  }

  /// Accepts Arabic-Indic digits and a comma decimal separator, both of which
  /// `double.tryParse` rejects outright (silently collapsing the fare to 0).
  static double parseFare(String value) {
    return double.tryParse(_latinDigits(value).replaceAll(',', '.')) ?? 0;
  }

  /// The same digit tolerance for the whole-number fields (ride count,
  /// duration) an operator types on an Arabic keyboard.
  static int parseCount(String value) {
    return int.tryParse(_latinDigits(value)) ?? 0;
  }

  static String _latinDigits(String value) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    final buffer = StringBuffer();
    for (final rune in value.trim().runes) {
      final char = String.fromCharCode(rune);
      final arabicIndex = arabic.indexOf(char);
      buffer.write(arabicIndex >= 0 ? '$arabicIndex' : char);
    }
    return buffer.toString();
  }

  static String formatFare(double value) {
    if (value <= 0) return '';
    final rounded = value.round();
    return value == rounded ? '$rounded' : value.toStringAsFixed(2);
  }
}
