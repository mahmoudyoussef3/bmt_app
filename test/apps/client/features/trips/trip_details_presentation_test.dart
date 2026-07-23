import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_details_view.dart';
import '../../client_test_app.dart';
import '../../tracking_cubit_stub.dart';

// Regression coverage for how Trip Details *reads*:
//
//  * it printed Supabase's raw columns at the passenger ("2026-07-06",
//    "04:00:00") instead of a formatted day and clock;
//  * it offered two destructive Cancel controls — one in the app bar, one in
//    the bottom bar;
//  * its hero and boarding cards overflowed on a normal phone surface.

TripData _trip({
  TripStatus status = TripStatus.upcoming,
  PaymentStatus paymentStatus = PaymentStatus.pending,
}) {
  return TripData(
    id: 'b1',
    reference: 'BK-8ADE6928',
    status: status,
    pickup: 'New Cairo, QH, Egypt',
    destination: 'American University in Cairo (AUC)',
    dateLabel: '2030-01-15',
    timeLabel: '04:00:00',
    driverName: 'Sam Adly',
    driverPhone: '',
    driverInitials: 'SA',
    driverRating: 4.8,
    vehicleName: 'Coaster',
    vehicleType: 'Minibus',
    vehicleId: 'v1',
    seats: const ['C1'],
    paymentStatus: paymentStatus,
    fare: 'EGP 50',
  );
}

Future<void> _pump(WidgetTester tester, TripData trip) async {
  await tester.binding.setSurfaceSize(const Size(430, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(clientTestApp(TripDetailsView(trip: trip)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(registerStubTrackingCubit);
  tearDown(unregisterStubTrackingCubit);

  testWidgets('departure is shown as a clock, never as a raw DB time', (
    tester,
  ) async {
    await _pump(tester, _trip());

    expect(find.text('04:00:00'), findsNothing);
    expect(find.text('2030-01-15'), findsNothing);
    expect(find.text('4:00 AM'), findsWidgets);
    expect(find.text('Tue, Jan 15'), findsWidgets);
  });

  testWidgets('a cancellable trip offers exactly one Cancel control', (
    tester,
  ) async {
    await _pump(tester, _trip());

    expect(find.text('Cancel Trip'), findsOneWidget);
    // The app bar's red "Cancel" text button is gone.
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('the hero owns the journey — no repeated Route section', (
    tester,
  ) async {
    await _pump(tester, _trip());

    // The drop-off is stated once, in the hero. The pickup also appears on the
    // boarding stub ("Board at …"), which is the one place repeating it earns
    // its keep; the old Route section restated all three facts for nothing.
    expect(find.text('American University in Cairo (AUC)'), findsOneWidget);
    expect(find.text('Pickup Point'), findsNothing);
    expect(find.text('Destination'), findsNothing);
  });

  testWidgets('trip details lay out without overflow on a phone surface', (
    tester,
  ) async {
    await _pump(tester, _trip());

    // Unlike the previous view, no exception is swallowed here.
    expect(tester.takeException(), isNull);
  });
}
