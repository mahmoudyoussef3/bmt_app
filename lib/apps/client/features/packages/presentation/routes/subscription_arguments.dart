import '../../domain/entities/package_plan.dart';

/// Arguments for `PackagesRoutes.subscription`.
///
/// The seat flow forwards the booked trip (driver, vehicle, route, fare)
/// through here so the payment step can show a real ticket instead of empty
/// placeholders. Opening the screen *without* booking context — from the
/// profile hub — means the rider has no trip picked yet, so tapping a package
/// sends them to choose a route first.
class SubscriptionArguments {
  const SubscriptionArguments({this.bookingData});

  factory SubscriptionArguments.fromArguments(Object? arguments) {
    return SubscriptionArguments(
      bookingData: arguments is Map
          ? Map<String, dynamic>.from(arguments)
          : null,
    );
  }

  final Map<String, dynamic>? bookingData;

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
