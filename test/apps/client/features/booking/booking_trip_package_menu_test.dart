import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/transport_office.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/core/pricing/trip_stop_pair_price.dart';

/// The rider is shown the packages the office put on *this trip*, with the
/// note the office wrote for them here — not a marketplace-wide catalogue the
/// trip has no price for.
void main() {
  const stopA = RoutePointData(id: 'stop-a', name: 'A', order: 1);
  const stopB = RoutePointData(id: 'stop-b', name: 'B', order: 2);
  const stopC = RoutePointData(id: 'stop-c', name: 'C', order: 3);

  const trip = RouteTripOptionData(
    id: 'trip-1',
    tripDate: '2026-08-25',
    departureTime: '08:00',
    arrivalTime: '11:00',
    availableSeats: 5,
    vehicleType: 'Standard',
    price: 'EGP 20',
    stopPricing: [
      TripStopPairPrice(
        fromPointId: 'stop-a',
        toPointId: 'stop-b',
        oneTimePrice: 20,
        packagePrices: {'pkg-week': 90},
        packageNotes: {'pkg-week': 'قصير: حتى محطة B فقط'},
      ),
      TripStopPairPrice(
        fromPointId: 'stop-a',
        toPointId: 'stop-c',
        oneTimePrice: 50,
        packagePrices: {'pkg-week': 220, 'pkg-uni': 400},
        packageNotes: {'pkg-uni': 'تشمل رحلة العودة بعد المحاضرة'},
      ),
    ],
  );

  const route = RouteOptionData(
    id: 'route-1',
    routeName: 'القاهرة - الإسكندرية',
    pickup: 'القاهرة',
    destination: 'الإسكندرية',
    distance: '220 كم',
    duration: '3 ساعات',
    availableSeats: 5,
    startingPrice: 'EGP 20',
    priceRange: 'EGP 20',
    availableTrips: [trip],
    office: TransportOffice(id: 'office-1', name: 'النيل'),
  );

  const uniPackage = PackagePlan(
    id: 'pkg-uni',
    nameAr: 'أسبوع الجامعة',
    nameEn: 'Campus Week',
    packageType: 'trip_1',
    durationDays: 7,
    rideCount: 6,
    price: 999, // the catalogue fallback, never what this trip charges
  );

  test('the menu is the chosen pair\'s, so a package sold only on the long '
      'corridor is not offered on the short one', () {
    final longLeg = BookingWizardSession(
      route: route,
    ).copyWith(selectedTrip: trip, pickupStop: stopA, dropoffStop: stopC);
    final shortLeg = BookingWizardSession(
      route: route,
    ).copyWith(selectedTrip: trip, pickupStop: stopA, dropoffStop: stopB);

    expect(longLeg.tripPackageIds, {'pkg-week', 'pkg-uni'});
    expect(shortLeg.tripPackageIds, {'pkg-week'});
  });

  test(
    'before the stops are narrowed down, the whole trip\'s menu is known',
    () {
      final session = BookingWizardSession(
        route: route,
      ).copyWith(selectedTrip: trip);

      expect(session.tripPackageIds, {'pkg-week', 'pkg-uni'});
    },
  );

  test('a trip with no packages offers none — the walk-up ticket is not one '
      'of them, and is fetched by shape instead', () {
    const bare = RouteTripOptionData(
      id: 'trip-2',
      tripDate: '2026-08-25',
      departureTime: '09:00',
      arrivalTime: '12:00',
      availableSeats: 5,
      vehicleType: 'Standard',
      price: 'EGP 30',
      stopPricing: [
        TripStopPairPrice(
          fromPointId: 'stop-a',
          toPointId: 'stop-c',
          oneTimePrice: 30,
        ),
      ],
    );
    final session = BookingWizardSession(
      route: route,
    ).copyWith(selectedTrip: bare, pickupStop: stopA, dropoffStop: stopC);

    expect(session.tripPackageIds, isEmpty);
  });

  test('the office\'s note for this trip reaches the rider', () {
    final session = BookingWizardSession(
      route: route,
    ).copyWith(selectedTrip: trip, pickupStop: stopA, dropoffStop: stopC);

    expect(session.packageNoteFor(uniPackage), 'تشمل رحلة العودة بعد المحاضرة');
  });

  test('a package the office wrote no note for shows none', () {
    const weekPackage = PackagePlan(
      id: 'pkg-week',
      nameAr: 'أسبوع',
      nameEn: 'Week',
      packageType: 'week',
      durationDays: 7,
      rideCount: 10,
      price: 700,
    );
    final session = BookingWizardSession(
      route: route,
    ).copyWith(selectedTrip: trip, pickupStop: stopA, dropoffStop: stopC);

    expect(session.packageNoteFor(weekPackage), isNull);
  });

  test(
    'a trip package is charged this trip\'s price, never the catalogue\'s',
    () {
      final session = BookingWizardSession(route: route).copyWith(
        selectedTrip: trip,
        pickupStop: stopA,
        dropoffStop: stopC,
        selectedPackage: uniPackage,
      );

      expect(session.resolvedPackagePrice(uniPackage), 400);
      expect(session.totalPrice, 400);
    },
  );
}
