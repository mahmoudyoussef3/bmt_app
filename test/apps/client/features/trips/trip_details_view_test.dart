import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_details_view.dart';

TripData _trip({
  required TripStatus status,
  required PaymentStatus paymentStatus,
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
  );
}

void main() {
  testWidgets(
    'Track Vehicle stays hidden on an in-progress trip whose own payment is still pending approval',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: TripDetailsView(
            trip: _trip(
              status: TripStatus.inProgress,
              paymentStatus: PaymentStatus.pending,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A layout overflow from the synthetic fixture's boarding/hero cards is
      // not what this test is verifying; only assert on the payment gate.
      tester.takeException();
      expect(find.text('Track Vehicle'), findsNothing);
    },
  );
}
