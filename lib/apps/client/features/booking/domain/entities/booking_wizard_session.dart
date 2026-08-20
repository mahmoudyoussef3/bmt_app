import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/core/pricing/trip_pricing_resolver.dart';

class BookingWizardSession {
  const BookingWizardSession({
    required this.route,
    this.pickupStop,
    this.dropoffStop,
    this.selectedTrip,
    this.selectedSeatId,
    this.selectedSeatLabel,
    this.selectedPackage,
    this.paymentMethod,
    this.receiptUrl,
    this.paymentReference,
    this.payerPhone,
    this.bookingId,
    this.bookingRef,
  });

  final RouteOptionData route;
  final RoutePointData? pickupStop;
  final RoutePointData? dropoffStop;
  final RouteTripOptionData? selectedTrip;
  final String? selectedSeatId;
  final String? selectedSeatLabel;
  final PackagePlan? selectedPackage;
  final String? paymentMethod;
  final String? receiptUrl;
  final String? paymentReference;
  final String? payerPhone;
  final String? bookingId;
  final String? bookingRef;

  bool get stopsValid =>
      pickupStop != null &&
      dropoffStop != null &&
      dropoffStop!.order > pickupStop!.order;

  bool get tripValid => selectedTrip != null;
  bool get seatValid => selectedSeatId != null;
  bool get packageValid => selectedPackage != null;

  /// A fare always starts on the day the rider actually travels — the trip they
  /// picked in the trip step. A package is never scheduled independently of it,
  /// so the rider is never asked for a start date.
  DateTime? get packageStartDate =>
      DateTime.tryParse(selectedTrip?.tripDate ?? '');
  bool get isCardPayment => paymentMethod == 'credit_card';
  bool get paymentValid =>
      paymentMethod != null && (isCardPayment || receiptUrl != null);

  /// The regular one-time fare for the exact pickup -> dropoff pair the
  /// rider selected, resolved from this trip's `trip_pricing` rows. Falls
  /// back to the trip's display price only when that exact pair has no
  /// dedicated pricing row (e.g. not yet configured on the Dashboard).
  double get tripPrice {
    final exact = TripPricingResolver.oneTimeFareFor(
      selectedTrip?.stopPricing ?? const [],
      pickupStop?.id,
      dropoffStop?.id,
    );
    return exact ??
        TripPricingResolver.parsePriceLabel(selectedTrip?.price ?? '0');
  }

  /// The ids of the packages the office put on the selected trip, taken from
  /// its `trip_package_prices` rows. This is the trip's fare menu: an office
  /// prices only what that departure actually sells, and may write a package
  /// that exists on no other trip.
  ///
  /// Read off the rider's exact stop pair when both stops are chosen — the
  /// pair they will be charged on — and otherwise off every active pricing
  /// row, so the menu is still known before the stops are narrowed down.
  Set<String> get tripPackageIds {
    final pricing = selectedTrip?.stopPricing ?? const [];
    final pair = TripPricingResolver.forPair(
      pricing,
      pickupStop?.id,
      dropoffStop?.id,
    );
    if (pair != null) return pair.packagePrices.keys.toSet();
    return {
      for (final row in pricing)
        if (row.isActive) ...row.packagePrices.keys,
    };
  }

  /// The office's note about [package] on this trip, or null when they wrote
  /// none.
  ///
  /// The rider's exact stop pair is authoritative once both stops are chosen —
  /// including when it carries no note. Falling through to another pair's note
  /// would show terms written about a corridor this rider is not travelling.
  /// Only before the stops are narrowed down is any active row read, so the
  /// menu can still be described.
  String? packageNoteFor(PackagePlan package) {
    final pricing = selectedTrip?.stopPricing ?? const [];
    final pair = TripPricingResolver.forPair(
      pricing,
      pickupStop?.id,
      dropoffStop?.id,
    );
    final note = pair != null
        ? pair.packageNotes[package.id]
        : pricing
              .where((row) => row.isActive)
              .map((row) => row.packageNotes[package.id])
              .firstWhere((note) => note != null, orElse: () => null);
    return (note == null || note.trim().isEmpty) ? null : note;
  }

  /// The package price for the exact pickup -> dropoff pair, resolved the
  /// same way as [tripPrice]. Falls back to the package catalog's flat
  /// price when the pair has no dedicated tier pricing configured.
  double resolvedPackagePrice(PackagePlan package) {
    final exact = TripPricingResolver.packageFareFor(
      selectedTrip?.stopPricing ?? const [],
      pickupStop?.id,
      dropoffStop?.id,
      package.id,
      package.durationDays,
      package.rideCount,
    );
    return exact ?? package.price;
  }

  double get totalPrice {
    final package = selectedPackage;
    if (package != null) return resolvedPackagePrice(package);
    return tripPrice;
  }

  String get priceSummary {
    if (!packageValid) return 'EGP ${tripPrice.toStringAsFixed(0)} / ride';
    return 'EGP ${totalPrice.toStringAsFixed(0)} total';
  }

  BookingWizardSession copyWith({
    RoutePointData? pickupStop,
    bool clearDropoff = false,
    RoutePointData? dropoffStop,
    RouteTripOptionData? selectedTrip,
    String? selectedSeatId,
    String? selectedSeatLabel,
    PackagePlan? selectedPackage,
    String? paymentMethod,
    String? receiptUrl,
    String? paymentReference,
    String? payerPhone,
    String? bookingId,
    String? bookingRef,
  }) {
    return BookingWizardSession(
      route: route,
      pickupStop: pickupStop ?? this.pickupStop,
      dropoffStop: clearDropoff ? null : (dropoffStop ?? this.dropoffStop),
      selectedTrip: selectedTrip ?? this.selectedTrip,
      selectedSeatId: selectedSeatId ?? this.selectedSeatId,
      selectedSeatLabel: selectedSeatLabel ?? this.selectedSeatLabel,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      paymentReference: paymentReference ?? this.paymentReference,
      payerPhone: payerPhone ?? this.payerPhone,
      bookingId: bookingId ?? this.bookingId,
      bookingRef: bookingRef ?? this.bookingRef,
    );
  }
}
