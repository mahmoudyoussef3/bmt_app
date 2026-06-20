import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/payments/presentation/screens/booking_confirmation_screen.dart';

void main() {
  testWidgets('BookingConfirmationScreen handles long destination text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: BookingConfirmationScreen(
          seat: '2',
          vehicleId: '3300 ggg',
          driver: 'mahmoud youssef',
          departureTime: '04:00:00',
          destination:
              'American University in Cairo (AUC) - New Cairo, Cairo Governorate, Egypt',
          bookingReference: 'BK-5AB25E7',
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Booking Confirmed'), findsOneWidget);
    expect(find.text('BK-5AB25E7'), findsOneWidget);
  });
}
