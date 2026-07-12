import 'package:bmt_app/apps/client/features/home/presentation/widgets/client_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpNav(
    WidgetTester tester, {
    required String activeTab,
    required ValueChanged<String> onTabChange,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: ClientBottomNavigation(
            activeTab: activeTab,
            onTabChange: onTabChange,
          ),
        ),
      ),
    );
  }

  group('ClientBottomNavigation', () {
    testWidgets('renders every destination', (tester) async {
      await pumpNav(tester, activeTab: 'home', onTabChange: (_) {});

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Routes'), findsOneWidget);
      expect(find.text('Trips'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('tapping an inactive tab reports that tab', (tester) async {
      final tapped = <String>[];
      await pumpNav(tester, activeTab: 'home', onTabChange: tapped.add);

      await tester.tap(find.text('Trips'));
      await tester.pumpAndSettle();

      expect(tapped, ['trips']);
    });

    testWidgets('tapping the active tab is a no-op', (tester) async {
      final tapped = <String>[];
      await pumpNav(tester, activeTab: 'home', onTabChange: tapped.add);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(tapped, isEmpty);
    });

    testWidgets('an unknown active tab falls back to the first destination', (
      tester,
    ) async {
      await pumpNav(tester, activeTab: 'unknown', onTabChange: (_) {});
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
