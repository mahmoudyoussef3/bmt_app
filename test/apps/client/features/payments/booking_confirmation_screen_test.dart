import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/payments/presentation/screens/booking_confirmation_screen.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

void main() {
  testWidgets('BookingConfirmationScreen handles long destination text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

  testWidgets(
    'BookingConfirmationScreen hides Track Vehicle while payment is awaiting verification',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BookingConfirmationScreen(
            seat: '2',
            vehicleId: '3300 ggg',
            driver: 'mahmoud youssef',
            departureTime: '04:00:00',
            destination: 'New Cairo',
            bookingReference: 'BK-5AB25E7',
            requiresVerification: true,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 950));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Payment Receipt Submitted'), findsOneWidget);
      // The vehicle must stay untrackable until payment is approved.
      expect(find.text('Track Vehicle'), findsNothing);
      expect(find.text('Back to Home'), findsOneWidget);
    },
  );
}
