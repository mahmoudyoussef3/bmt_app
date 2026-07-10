import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/core/pricing/trip_stop_pair_price.dart';

void main() {
  const route = RouteOptionData(
    id: 'route-1',
    routeName: 'القاهرة - الإسكندرية',
    pickup: 'القاهرة',
    destination: 'الإسكندرية',
    distance: '220 كم',
    duration: '3 ساعات',
    availableSeats: 1,
    startingPrice: 'EGP 100',
    priceRange: 'EGP 100',
    availableTrips: [],
  );
  const package = PackagePlan(
    id: 'package-1',
    nameAr: 'ذهاب فقط',
    nameEn: 'Just Go',
    packageType: 'just_go',
    durationDays: 1,
    rideCount: 1,
    price: 100,
  );

  // Stop A -> B is cheap; A -> C (the pair actually booked below) is
  // configured on the Dashboard at a higher fare/package price. A bug that
  // resolves "any" pricing row instead of the exact pair would surface the
  // A->B numbers here instead.
  const stopA = RoutePointData(id: 'stop-a', name: 'A', order: 1);
  const stopB = RoutePointData(id: 'stop-b', name: 'B', order: 2);
  const stopC = RoutePointData(id: 'stop-c', name: 'C', order: 3);
  const tripWithPairPricing = RouteTripOptionData(
    id: 'trip-1',
    departureTime: '08:00',
    arrivalTime: '11:00',
    availableSeats: 5,
    vehicleType: 'Standard',
    price: 'EGP 20', // aggregate/cheapest label — must NOT be used verbatim
    stopPricing: [
      TripStopPairPrice(
        fromPointId: 'stop-a',
        toPointId: 'stop-b',
        oneTimePrice: 20,
        fiveDaysPrice: 90,
        tenDaysPrice: 170,
        monthlyPrice: 450,
        threeMonthsPrice: 1200,
      ),
      TripStopPairPrice(
        fromPointId: 'stop-a',
        toPointId: 'stop-c',
        oneTimePrice: 50,
        fiveDaysPrice: 220,
        tenDaysPrice: 400,
        monthlyPrice: 1100,
        threeMonthsPrice: 3000,
      ),
    ],
  );

  test(
    'manual payment is valid only after method and receipt are provided',
    () {
      final session = BookingWizardSession(route: route)
          .copyWith(paymentMethod: 'instapay')
          .copyWith(receiptUrl: 'signed-receipt-url');

      expect(session.paymentValid, isTrue);
    },
  );

  test('card payment is valid without a manual receipt', () {
    final session = BookingWizardSession(
      route: route,
    ).copyWith(paymentMethod: 'credit_card');

    expect(session.paymentValid, isTrue);
    expect(session.isCardPayment, isTrue);
  });

  test('a server package and start date are required', () {
    final empty = BookingWizardSession(route: route);
    final withoutDate = empty.copyWith(selectedPackage: package);

    expect(empty.packageValid, isFalse);
    expect(withoutDate.packageValid, isFalse);
    expect(
      withoutDate.copyWith(packageStartDate: DateTime(2026, 7, 5)).packageValid,
      isTrue,
    );
  });

  test('package price is the server-facing total shown to the client', () {
    final session = BookingWizardSession(route: route).copyWith(
      selectedPackage: package,
      packageStartDate: DateTime(2026, 7, 4),
    );

    expect(session.packageValid, isTrue);
    expect(session.totalPrice, 100);
  });

  test(
    'trip fare resolves the exact pickup->dropoff pair, not an aggregate '
    'or unrelated row (regression for the Dashboard/Client fare mismatch)',
    () {
      final session = BookingWizardSession(route: route).copyWith(
        selectedTrip: tripWithPairPricing,
        pickupStop: stopA,
        dropoffStop: stopC,
      );

      // A->C was configured at 50, not the trip's cheapest label (20,
      // which belongs to the A->B pair).
      expect(session.tripPrice, 50);
    },
  );

  test(
    'trip fare falls back to the trip label when the exact pair has no '
    'dedicated trip_pricing row (graceful degradation, not a crash)',
    () {
      final session = BookingWizardSession(route: route).copyWith(
        selectedTrip: tripWithPairPricing,
        pickupStop: stopB,
        dropoffStop: stopC,
      );

      expect(session.tripPrice, 20);
    },
  );

  test(
    'package price resolves the tier for the exact stop pair instead of '
    'the generic catalog price (regression for package price mismatch)',
    () {
      // durationDays=5 matches transport_packages' real "work_week" shape
      // (seeded as duration_days=5, ride_count=10) — package_type text is
      // NOT what tier resolution keys on (see next two tests).
      const fiveDayPackage = PackagePlan(
        id: 'package-5d',
        nameAr: 'أسبوع عمل',
        nameEn: 'Work Week',
        packageType: 'work_week',
        durationDays: 5,
        rideCount: 10,
        price: 999, // generic catalog price — must be overridden
      );
      final session = BookingWizardSession(route: route).copyWith(
        selectedTrip: tripWithPairPricing,
        pickupStop: stopA,
        dropoffStop: stopC,
        selectedPackage: fiveDayPackage,
        packageStartDate: DateTime(2026, 7, 4),
      );

      // Dashboard configured A->C's five-day tier at 220, not the
      // catalog's flat 999.
      expect(session.resolvedPackagePrice(fiveDayPackage), 220);
      expect(session.totalPrice, 220);
    },
  );

  test(
    'a single-ride ("just_go") package resolves to the pair\'s one-time '
    'fare, matched by shape (duration/ride count) not by package_type text',
    () {
      const justGo = PackagePlan(
        id: 'package-just-go',
        nameAr: 'رحلة ذهاب فقط',
        nameEn: 'Just Go',
        packageType: 'just_go',
        durationDays: 1,
        rideCount: 1,
        price: 85,
      );
      final session = BookingWizardSession(route: route).copyWith(
        selectedTrip: tripWithPairPricing,
        pickupStop: stopA,
        dropoffStop: stopC,
      );

      expect(session.resolvedPackagePrice(justGo), 50);
    },
  );

  test(
    'a package shape with no trip_pricing equivalent (e.g. a same-day '
    'round trip: durationDays=1 but rideCount>1) falls back to the '
    'catalog price instead of guessing',
    () {
      const goAndReturn = PackagePlan(
        id: 'package-go-return',
        nameAr: 'رحلة ذهاب وعودة',
        nameEn: 'Go & Return',
        packageType: 'go_and_return',
        durationDays: 1,
        rideCount: 2,
        price: 160,
      );
      final session = BookingWizardSession(route: route).copyWith(
        selectedTrip: tripWithPairPricing,
        pickupStop: stopA,
        dropoffStop: stopC,
      );

      expect(session.resolvedPackagePrice(goAndReturn), 160);
    },
  );

  test('payment metadata survives seat reset', () async {
    final cubit = BookingWizardCubit(route)
      ..selectPaymentMethod('bank_transfer')
      ..setReceiptUrl('signed-receipt-url')
      ..setManualPaymentDetails(
        paymentReference: 'REF-123',
        payerPhone: '01000000000',
      )
      ..clearSeat();

    expect(cubit.state.paymentReference, 'REF-123');
    expect(cubit.state.payerPhone, '01000000000');
    expect(cubit.state.receiptUrl, 'signed-receipt-url');
    await cubit.close();
  });
}
