import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_upcoming_trip_card.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_upcoming_trips_list.dart';

UpcomingTripData _trip({
  String departureTime = '08:30:00',
  String tripDate = '',
  String price = 'EGP 100',
  int seatsLeft = 14,
  bool isLive = false,
  HomeBookingStatus? bookedStatus,
  int bookedSeats = 0,
}) {
  return UpcomingTripData(
    tripId: 't1',
    routeId: 'r1',
    routeName: 'test new route',
    pickup: 'El-Marg, QH, Egypt',
    destination: 'American University in Cairo (AUC)',
    tripDate: tripDate,
    departureTime: departureTime,
    duration: '1h 19m',
    price: price,
    seatsLeft: seatsLeft,
    isLive: isLive,
    bookedStatus: bookedStatus,
    bookedSeats: bookedSeats,
  );
}

Future<void> _pumpList(
  WidgetTester tester,
  List<UpcomingTripData> trips, {
  ValueChanged<UpcomingTripData>? onBook,
  Brightness brightness = Brightness.light,
}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        // The feed is a sliver so Home can build its cards lazily; it only
        // renders inside a scroll view that accepts slivers.
        body: CustomScrollView(
          slivers: [
            HomeUpcomingTripsList(
              trips: trips,
              onBook: onBook ?? (_) {},
              onBrowseRoutes: () {},
            ),
          ],
        ),
      ),
    ),
  );
}

/// Renders at the width of the smallest phone the client app ships to, so a
/// layout that only fits on a tablet fails here rather than in a rider's hand.
Future<void> _pumpOnNarrowPhone(
  WidgetTester tester,
  List<UpcomingTripData> trips, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await _pumpList(tester, trips, brightness: brightness);
}

void main() {
  group('trip schedule formatting', () {
    testWidgets('renders a raw Supabase time as a clock label', (tester) async {
      late String time;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              time = formatTripTime(context, '08:30:00');
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(time, '8:30 AM');
    });

    testWidgets('an unset time formats to empty rather than a fake hour', (
      tester,
    ) async {
      late String time;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              time = formatTripTime(context, '');
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(time, isEmpty);
    });

    testWidgets("today's date reads as Today", (tester) async {
      late String day;
      final today = DateTime.now().toIso8601String().split('T').first;
      await tester.pumpWidget(
        MaterialApp(
          // "Today" is a localized label, so this needs the real delegates.
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              day = formatTripDay(context, today);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(day, 'Today');
    });
  });

  group('HomeUpcomingTripsList', () {
    testWidgets('shows the departure, both stops, seats and fare', (
      tester,
    ) async {
      await _pumpList(tester, [_trip()]);

      expect(find.text('8:30 AM'), findsOneWidget);
      expect(find.text('El-Marg, QH, Egypt'), findsOneWidget);
      expect(find.text('American University in Cairo (AUC)'), findsOneWidget);
      expect(find.text('14 available'), findsOneWidget);
      expect(find.text('EGP 100'), findsOneWidget);
    });

    testWidgets('books the tapped trip', (tester) async {
      UpcomingTripData? booked;
      await _pumpList(tester, [_trip()], onBook: (trip) => booked = trip);

      await tester.tap(find.text('Book seat'));
      await tester.pump();

      expect(booked?.tripId, 't1');
    });

    testWidgets('a sold-out trip cannot be booked', (tester) async {
      UpcomingTripData? booked;
      await _pumpList(tester, [
        _trip(seatsLeft: 0),
      ], onBook: (trip) => booked = trip);

      expect(find.text('Sold out'), findsNWidgets(2));
      await tester.tap(find.text('Sold out').last);
      await tester.pump();

      expect(booked, isNull);
    });

    testWidgets('scarce seats are called out', (tester) async {
      await _pumpList(tester, [_trip(seatsLeft: 3)]);

      expect(find.text('Only 3 left'), findsOneWidget);
    });

    testWidgets('an unpriced trip says so instead of showing a fake fare', (
      tester,
    ) async {
      await _pumpList(tester, [_trip(price: '')]);

      expect(find.text('Fare not published yet'), findsOneWidget);
    });

    // Home hides the whole departures zone when nothing is on sale, so the
    // rail must not leave an empty-state row (or its progress rule) behind.
    testWidgets('with no trips it draws nothing at all', (tester) async {
      await _pumpList(tester, []);

      expect(find.byType(HomeUpcomingTripCard), findsNothing);
      expect(find.text('All routes'), findsNothing);
      expect(find.byType(ListView), findsNothing);
    });
  });

  // A departure the rider already holds a seat on must not look untouched: it
  // stays in the feed and stays bookable — riders book the same trip again for
  // a friend — but it has to say that they booked it and where that booking
  // stands.
  group('a departure the rider has already booked', () {
    testWidgets('carries its booking status', (tester) async {
      await _pumpList(tester, [
        _trip(bookedStatus: HomeBookingStatus.underReview, bookedSeats: 1),
      ]);

      expect(find.text('Under review'), findsOneWidget);
      expect(find.text('You booked this'), findsOneWidget);
    });

    testWidgets('counts the seats already held', (tester) async {
      await _pumpList(tester, [
        _trip(bookedStatus: HomeBookingStatus.confirmed, bookedSeats: 2),
      ]);

      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('You booked 2 seats'), findsOneWidget);
    });

    testWidgets('can still be booked again, and says so', (tester) async {
      UpcomingTripData? booked;
      await _pumpList(tester, [
        _trip(bookedStatus: HomeBookingStatus.underReview, bookedSeats: 1),
      ], onBook: (trip) => booked = trip);

      expect(find.text('Book seat'), findsNothing);
      await tester.tap(find.text('Book another seat'));
      await tester.pump();

      expect(booked?.tripId, 't1');
    });

    testWidgets('an unbooked trip shows no booking status', (tester) async {
      await _pumpList(tester, [_trip()]);

      expect(find.text('Under review'), findsNothing);
      expect(find.text('You booked this'), findsNothing);
      expect(find.text('Book seat'), findsOneWidget);
    });
  });

  // The card is a boarding pass: a tinted departure band, the journey, a facts
  // panel, then the fare and the action below a tear line. Each zone carries
  // text that can grow — a long route name, a two-line status, a booked note —
  // so every state has to survive the narrowest phone the app ships to. An
  // overflow here fails the test rather than shipping a striped card.
  group('the ticket layout', () {
    testWidgets('fits a narrow phone', (tester) async {
      await _pumpOnNarrowPhone(tester, [_trip()]);

      expect(find.byType(HomeUpcomingTripCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits a narrow phone with a booking on it', (tester) async {
      await _pumpOnNarrowPhone(tester, [
        _trip(bookedStatus: HomeBookingStatus.underReview, bookedSeats: 2),
      ]);

      expect(find.text('You booked 2 seats'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits a narrow phone when boarding and sold out', (
      tester,
    ) async {
      await _pumpOnNarrowPhone(tester, [_trip(seatsLeft: 0, isLive: true)]);

      expect(find.text('Boarding'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark mode', (tester) async {
      await _pumpOnNarrowPhone(tester, [
        _trip(bookedStatus: HomeBookingStatus.onBoard, bookedSeats: 1),
      ], brightness: Brightness.dark);

      expect(find.byType(HomeUpcomingTripCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
