import '../../domain/entities/package_plan.dart';

/// Arguments for `PackagesRoutes.subscription`.
///
/// The seat flow forwards the booked trip (driver, vehicle, route, fare)
/// through here so the payment step can show a real ticket instead of empty
/// placeholders. Opening the screen *without* booking context — from the
/// profile hub or an office profile — means the rider has no trip picked yet,
/// so the subscribe CTA sends them to choose a route first.
///
/// An office profile also passes [initialOfficeId] so the marketplace opens
/// already filtered to that seller.
class SubscriptionArguments {
  const SubscriptionArguments({this.bookingData, this.initialOfficeId});

  factory SubscriptionArguments.fromArguments(Object? arguments) {
    if (arguments is! Map) return const SubscriptionArguments();

    final map = Map<String, dynamic>.from(arguments);
    // The office hint rides the same argument channel as booking data but is
    // not itself a trip, so it is lifted out before deciding whether a trip is
    // present. What remains is booking context only when it still holds trip
    // fields — an office-only navigation leaves the map empty.
    final officeId = map.remove('initialOfficeId')?.toString();

    return SubscriptionArguments(
      bookingData: map.isEmpty ? null : map,
      initialOfficeId: (officeId != null && officeId.isNotEmpty)
          ? officeId
          : null,
    );
  }

  final Map<String, dynamic>? bookingData;

  /// The office the marketplace should open filtered to, or `null` for the whole
  /// marketplace.
  final String? initialOfficeId;

  bool get hasBookingContext => bookingData != null;

  /// The payload handed to checkout: the forwarded trip plus the chosen plan.
  Map<String, dynamic> checkoutPayload(PackagePlan package) {
    return <String, dynamic>{
      ...?bookingData,
      'packageId': package.id,
      'package': package.displayName,
      'baseFare': package.priceInPounds,
    };
  }
}
