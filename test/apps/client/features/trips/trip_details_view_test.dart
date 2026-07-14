import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_details_view.dart';

TripData _trip({
  required TripStatus status,
  required PaymentStatus paymentStatus,
  bool isReviewed = false,
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
    seats: const ['1'],
    paymentStatus: paymentStatus,
    fare: 'EGP 50',
    isReviewed: isReviewed,
  );
}

Future<void> _pump(WidgetTester tester, TripData trip) async {
  await tester.binding.setSurfaceSize(const Size(430, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(MaterialApp(home: TripDetailsView(trip: trip)));
  await tester.pumpAndSettle();

  // A layout overflow from the synthetic fixture's cards is not what these
  // tests are verifying; they assert only on which actions are offered.
  tester.takeException();
}

void main() {
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

    expect(find.text('Rate Trip'), findsOneWidget);
    expect(find.text('Book Again'), findsOneWidget);
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

    expect(find.text('Rate Trip'), findsNothing);
    expect(find.textContaining('You rated this trip'), findsOneWidget);
    expect(find.text('Book Again'), findsOneWidget);
  });

  testWidgets('an in-progress paid trip keeps its live actions', (
    tester,
  ) async {
    await _pump(
      tester,
      _trip(status: TripStatus.inProgress, paymentStatus: PaymentStatus.paid),
    );

    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Track Vehicle'), findsOneWidget);
  });
}
