import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/route_type_classifier.dart';
import 'package:bmt_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RouteOptionData _routeWithStops(int stopCount) {
  return RouteOptionData(
    id: 'r1',
    routeName: 'Test Route',
    pickup: 'A',
    destination: 'B',
    distance: '10 km',
    duration: '30 min',
    availableSeats: 4,
    startingPrice: r'$10',
    priceRange: r'$10-$15',
    availableTrips: const [],
    points: List.generate(
      stopCount,
      (index) => RoutePointData(name: 'Stop $index', order: index),
    ),
  );
}

void main() {
  group('classifyRouteType', () {
    test('classifies a route with no intermediate stops as direct', () {
      expect(classifyRouteType(_routeWithStops(0)), RouteType.direct);
    });

    test('classifies a route at the direct-stop threshold (2) as direct', () {
      expect(classifyRouteType(_routeWithStops(2)), RouteType.direct);
    });

    test('classifies a route with more than 2 stops as multi-stop', () {
      expect(classifyRouteType(_routeWithStops(3)), RouteType.multiStop);
    });
  });

  group('routeTypeLabel', () {
    // The label is localized, so it needs a context under the app's
    // localization delegates rather than a plain unit-test call.
    testWidgets('labels direct and multi-stop routes', (tester) async {
      late BuildContext context;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(routeTypeLabel(context, RouteType.direct), 'Direct');
      expect(routeTypeLabel(context, RouteType.multiStop), 'Multi-stop');
    });
  });
}
