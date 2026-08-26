import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_details_view.dart';
import '../../client_test_app.dart';
import '../../tracking_cubit_stub.dart';

/// [bookingState] defaults to `confirmed`: these cases describe bookings the
/// operator has approved. A `reserved` booking is only a held seat, and Trip
/// Details is expected to say so rather than offer journey actions — covered in
/// `trip_attention_test.dart`.
TripData _trip({
  required TripStatus status,
  required PaymentStatus paymentStatus,
  BookingState bookingState = BookingState.confirmed,
  bool isReviewed = false,
  List<String> vehicleImageUrls = const [],
}) {
  return TripData(
    id: 'b1',
    reference: 'BMT-TEST',
    status: status,
    pickup: 'A',
    destination: 'B',
    dateLabel: 'Today',
    timeLabel: '08:00',
    driverName: 'Sam',
    driverPhone: '',
    driverInitials: 'SA',
    driverRating: 4.8,
    vehicleName: 'Coaster',
    vehicleType: 'Minibus',
    vehicleId: 'v1',
    vehiclePlate: 'ABC 123',
    vehicleImageUrls: vehicleImageUrls,
    seats: const ['1'],
    paymentStatus: paymentStatus,
    bookingState: bookingState,
    fare: 'EGP 50',
    isReviewed: isReviewed,
  );
}

Future<void> _pump(WidgetTester tester, TripData trip) async {
  await tester.binding.setSurfaceSize(const Size(430, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(clientTestApp(TripDetailsView(trip: trip)));
  await tester.pumpAndSettle();

  // A layout overflow from the synthetic fixture's cards is not what these
  // tests are verifying; they assert only on which actions are offered.
  tester.takeException();
}

void main() {
  setUp(registerStubTrackingCubit);
  tearDown(unregisterStubTrackingCubit);

  testWidgets(
    'Track Vehicle stays hidden on an in-progress trip whose own payment is still pending approval',
    (tester) async {
      await _pump(
        tester,
        _trip(
          status: TripStatus.inProgress,
          paymentStatus: PaymentStatus.pending,
        ),
      );

      expect(find.text('Track Vehicle'), findsNothing);
    },
  );

  testWidgets('a completed trip offers no call, chat, or tracking', (
    tester,
  ) async {
    await _pump(
      tester,
      _trip(status: TripStatus.completed, paymentStatus: PaymentStatus.paid),
    );

    expect(find.text('Call'), findsNothing);
    expect(find.text('Chat'), findsNothing);
    expect(find.text('Track'), findsNothing);
    expect(find.text('Track Vehicle'), findsNothing);
  });

  testWidgets('a cancelled trip offers no call, chat, or tracking', (
    tester,
  ) async {
    await _pump(
      tester,
      _trip(
        status: TripStatus.cancelled,
        paymentStatus: PaymentStatus.refunded,
      ),
    );

    expect(find.text('Call'), findsNothing);
    expect(find.text('Chat'), findsNothing);
    expect(find.text('Track'), findsNothing);
  });

  testWidgets('an unrated completed trip can still be rated', (tester) async {
    await _pump(
      tester,
      _trip(status: TripStatus.completed, paymentStatus: PaymentStatus.paid),
    );

    expect(find.text('Rate this trip'), findsOneWidget);
    expect(find.text('Book another trip'), findsOneWidget);
  });

  testWidgets('a completed trip that was already rated never asks again', (
    tester,
  ) async {
    await _pump(
      tester,
      _trip(
        status: TripStatus.completed,
        paymentStatus: PaymentStatus.paid,
        isReviewed: true,
      ),
    );

    expect(find.text('Rate this trip'), findsNothing);
    expect(find.textContaining('You rated this trip'), findsOneWidget);
    expect(find.text('Book another trip'), findsOneWidget);
  });

  testWidgets('an in-progress paid trip keeps tracking and shows what it cost', (
    tester,
  ) async {
    await _pump(
      tester,
      _trip(status: TripStatus.inProgress, paymentStatus: PaymentStatus.paid),
    );

    // Track Vehicle sits in the docked action bar. Under the hero there are now
    // exactly two cards — who is driving what, and what it cost. The boarding
    // pass and the seat map went for restating what the hero already says.
    expect(find.text('Track Vehicle'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('ABC 123'), findsOneWidget);
    expect(find.text('Total paid'), findsOneWidget);
    expect(find.text('EGP 50'), findsOneWidget);
    expect(find.text('Boarding pass'), findsNothing);
    expect(find.text('Seats'), findsNothing);
  });

  testWidgets('a bus with no photos on file says so, and offers no gallery', (
    tester,
  ) async {
    await _pump(
      tester,
      _trip(status: TripStatus.inProgress, paymentStatus: PaymentStatus.paid),
    );

    // The frame still draws, labelled: an empty gap reads as a broken screen.
    // What must not appear is the count chip, which promises a gallery.
    expect(find.text('No photos of this vehicle yet'), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d+ photos')), findsNothing);
  });

  testWidgets('a photographed bus can be tapped open', (tester) async {
    await _pump(
      tester,
      _trip(
        status: TripStatus.inProgress,
        paymentStatus: PaymentStatus.paid,
        vehicleImageUrls: const [
          'https://example.test/a.png',
          'https://example.test/b.png',
        ],
      ),
    );

    expect(find.text('2 photos'), findsOneWidget);

    await tester.tap(find.text('2 photos'));
    await tester.pumpAndSettle();

    // The sheet names the bus it is showing, so it can never be mistaken for
    // photos of some other vehicle.
    expect(find.text('Coaster'), findsWidgets);
    expect(find.text('Minibus · ABC 123'), findsOneWidget);
  });
}
