import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_bookings_list.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

HomeBookingData _booking({
  String id = 'b1',
  HomeBookingStatus status = HomeBookingStatus.underReview,
  String seatLabel = 'A3',
  String fare = 'EGP 100',
}) {
  return HomeBookingData(
    id: id,
    tripId: 't1',
    bookingNumber: 'BK-1A2B3C4D',
    status: status,
    pickup: 'El-Marg, QH, Egypt',
    destination: 'American University in Cairo (AUC)',
    tripDate: DateTime.now().toIso8601String().split('T').first,
    departureTime: '08:30:00',
    seatLabel: seatLabel,
    fare: fare,
  );
}

Future<void> _pump(
  WidgetTester tester,
  List<HomeBookingData> bookings, {
  ValueChanged<HomeBookingData>? onTrack,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeBookingsList(
            bookings: bookings,
            onTrack: onTrack ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('HomeBookingsList', () {
    // The bug this section exists to fix: a rider who had just paid saw nothing
    // at all about their booking on Home.
    testWidgets('a booking under review shows its status and what happens next',
        (tester) async {
      await _pump(tester, [_booking()]);

      expect(find.text('#BK-1A2B3C4D'), findsOneWidget);
      expect(find.text('Under review'), findsOneWidget);
      expect(find.text('8:30 AM'), findsOneWidget);
      expect(find.text('· Today'), findsOneWidget);
      expect(find.text('A3'), findsOneWidget);
      expect(find.text('EGP 100'), findsOneWidget);
      expect(
        find.textContaining('We are checking your payment'),
        findsOneWidget,
      );
    });

    testWidgets('a booking under review offers no tracking yet', (
      tester,
    ) async {
      HomeBookingData? tracked;
      await _pump(tester, [_booking()], onTrack: (b) => tracked = b);

      expect(find.text('Track your bus'), findsNothing);
      await tester.tap(find.text('#BK-1A2B3C4D'));
      await tester.pump();

      expect(tracked, isNull);
    });

    testWidgets('a confirmed booking can be tracked', (tester) async {
      HomeBookingData? tracked;
      await _pump(
        tester,
        [_booking(status: HomeBookingStatus.confirmed)],
        onTrack: (b) => tracked = b,
      );

      expect(find.text('Confirmed'), findsOneWidget);
      await tester.tap(find.text('Track your bus'));
      await tester.pump();

      expect(tracked?.id, 'b1');
    });

    // A booking holds exactly one seat, so a rider taking a party of seats
    // holds one booking per seat and each shows its own seat label.
    testWidgets('every seat the rider holds shows its own label', (
      tester,
    ) async {
      await _pump(tester, [
        _booking(seatLabel: 'A3'),
        _booking(id: 'b2', seatLabel: 'A4'),
      ]);

      expect(find.text('A3'), findsOneWidget);
      expect(find.text('A4'), findsOneWidget);
    });

    testWidgets('renders every booking the rider holds', (tester) async {
      await _pump(tester, [
        _booking(),
        _booking(id: 'b2', status: HomeBookingStatus.confirmed),
      ]);

      expect(find.text('Under review'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
    });
  });
}
