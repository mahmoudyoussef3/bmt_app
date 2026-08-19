import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/routes/domain/entities/route_availability.dart';
import 'package:bmt_app/apps/client/features/routes/domain/entities/route_summary.dart';
import 'package:bmt_app/apps/client/features/routes/presentation/widgets/route_card.dart';

import '../../client_test_app.dart';

String _today() => DateTime.now().toIso8601String().split('T').first;

Future<void> _pumpCard(
  WidgetTester tester,
  RouteAvailability availability,
) async {
  await tester.pumpWidget(
    clientTestApp(
      Scaffold(
        body: RouteCard(
          route: RouteSummary(
            id: 'A',
            name: 'Cairo Express',
            startCity: 'Cairo',
            endCity: 'Mansoura',
            officeName: 'Nile Express',
            availability: availability,
          ),
          onTap: () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a selling corridor says so, and when it next leaves', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      RouteAvailability(
        status: RouteAvailabilityStatus.bookable,
        nextDepartureDate: _today(),
        nextDepartureTime: '08:00:00',
        seatsLeft: 9,
        tripCount: 3,
      ),
    );

    expect(find.text('Available to book'), findsOneWidget);
    expect(find.textContaining('Next departure Today'), findsOneWidget);
  });

  testWidgets('a full corridor reads as booked out, not as missing', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      RouteAvailability(
        status: RouteAvailabilityStatus.soldOut,
        nextDepartureDate: _today(),
        nextDepartureTime: '08:00:00',
      ),
    );

    expect(find.text('Fully booked'), findsOneWidget);
    expect(find.text('Available to book'), findsNothing);
    expect(find.textContaining('Next departure Today'), findsOneWidget);
  });

  testWidgets('a corridor with nothing on sale names no departure', (
    tester,
  ) async {
    await _pumpCard(tester, RouteAvailability.none);

    expect(find.text('No trips on sale'), findsOneWidget);
    expect(find.textContaining('Next departure'), findsNothing);
  });

  testWidgets('an unread outlook claims nothing at all', (tester) async {
    await _pumpCard(tester, RouteAvailability.unknown);

    expect(find.text('Available to book'), findsNothing);
    expect(find.text('Fully booked'), findsNothing);
    expect(find.text('No trips on sale'), findsNothing);
  });

  testWidgets('the last few seats are called out', (tester) async {
    await _pumpCard(
      tester,
      RouteAvailability(
        status: RouteAvailabilityStatus.bookable,
        nextDepartureDate: _today(),
        nextDepartureTime: '08:00:00',
        seatsLeft: 2,
        tripCount: 1,
      ),
    );

    expect(find.text('2 seats left'), findsOneWidget);
  });

  testWidgets('a half-empty bus does not nag about seats', (tester) async {
    await _pumpCard(
      tester,
      RouteAvailability(
        status: RouteAvailabilityStatus.bookable,
        nextDepartureDate: _today(),
        nextDepartureTime: '08:00:00',
        seatsLeft: 11,
        tripCount: 2,
      ),
    );

    expect(find.textContaining('seats left'), findsNothing);
  });

  testWidgets('a departure with no time set still names its day', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      RouteAvailability(
        status: RouteAvailabilityStatus.bookable,
        nextDepartureDate: _today(),
        seatsLeft: 6,
        tripCount: 1,
      ),
    );

    expect(find.text('Next departure Today'), findsOneWidget);
  });
}
