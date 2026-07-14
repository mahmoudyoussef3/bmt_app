import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_active_package_card.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_sections.dart';

HomeData _data({HomeActivePackageData? activePackage}) => HomeData(
  upcomingTrips: const [],
  pickupSuggestions: const [],
  destinationSuggestions: const [],
  timeSuggestions: const [],
  userName: 'Mahmoud',
  activePackage: activePackage,
);

/// Home sections reveal on a staggered delay, so let those timers fire before
/// asserting on what is on screen.
Future<void> _pumpSections(WidgetTester tester, HomeData data) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeSections(
            data: data,
            isTablet: false,
            onOpenRoute: (_, [_]) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  group('Home packages section', () {
    // Home must not advertise plans: it only reflects a subscription the
    // rider already pays for.
    testWidgets('is hidden when the rider has no subscription', (tester) async {
      await _pumpSections(tester, _data());

      expect(find.byType(HomeActivePackageCard), findsNothing);
      expect(find.text('Active subscription'), findsNothing);
    });

    testWidgets('shows the active subscription when the rider has one', (
      tester,
    ) async {
      final now = DateTime.now();
      await _pumpSections(
        tester,
        _data(
          activePackage: HomeActivePackageData(
            title: 'Monthly package',
            routeLabel: 'El-Marg → AUC',
            startDate: now.subtract(const Duration(days: 10)),
            endDate: now.add(const Duration(days: 20)),
          ),
        ),
      );

      expect(find.byType(HomeActivePackageCard), findsOneWidget);
      expect(find.text('Monthly package'), findsOneWidget);
      expect(find.text('20 days left'), findsOneWidget);
    });
  });

  group('Home support section', () {
    // Support is reachable from the quick actions and settings, so Home does
    // not repeat it below the fold.
    testWidgets('is not rendered on Home', (tester) async {
      await _pumpSections(tester, _data());

      expect(find.textContaining('Support'), findsNothing);
      expect(find.textContaining('support'), findsNothing);
    });
  });
}
