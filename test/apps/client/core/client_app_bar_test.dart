import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

import '../client_test_app.dart';

/// Pushes [child] on top of a first route, so the bar sees something to pop.
Future<void> _pumpPushed(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    clientTestApp(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => child),
          ),
          child: const Text('go'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
}

void main() {
  group('ClientAppBar', () {
    testWidgets('a root screen grows no back button', (tester) async {
      await tester.pumpWidget(
        clientTestApp(
          const Scaffold(appBar: ClientAppBar(title: 'Home')),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('a pushed screen gets a back button that pops', (tester) async {
      await _pumpPushed(
        tester,
        const Scaffold(appBar: ClientAppBar(title: 'Details')),
      );
      expect(find.text('Details'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Details'), findsNothing);
      expect(find.text('go'), findsOneWidget);
    });

    testWidgets('onBack overrides popping, for pane-by-pane flows', (
      tester,
    ) async {
      var taps = 0;
      await _pumpPushed(
        tester,
        Scaffold(appBar: ClientAppBar(title: 'Step 2', onBack: () => taps++)),
      );

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(
        find.text('Step 2'),
        findsOneWidget,
        reason: 'the custom handler runs instead of the route popping',
      );
    });

    testWidgets('backEnabled false keeps the arrow but makes it inert', (
      tester,
    ) async {
      // A booking mid-confirm must not be abandonable, but removing the arrow
      // outright would reflow the header at the worst moment.
      await _pumpPushed(
        tester,
        const Scaffold(
          appBar: ClientAppBar(title: 'Confirming', backEnabled: false),
        ),
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('a long title ellipsizes rather than overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        clientTestApp(
          const Scaffold(
            appBar: ClientAppBar(
              title: 'An extremely long screen title that cannot possibly fit '
                  'inside a phone-width toolbar without being truncated',
              subtitle: 'And a subtitle that is also far too long to fit here',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final title = tester.widget<Text>(
        find.textContaining('An extremely long screen title').first,
      );
      expect(title.overflow, TextOverflow.ellipsis);
      expect(title.maxLines, 1);
    });

    testWidgets('subtitle and leading render together', (tester) async {
      await tester.pumpWidget(
        clientTestApp(
          const Scaffold(
            appBar: ClientAppBar(
              title: 'Cairo → Alexandria',
              subtitle: 'Nile Express',
              leading: Icon(Icons.route_rounded),
            ),
          ),
        ),
      );

      expect(find.text('Cairo → Alexandria'), findsOneWidget);
      expect(find.text('Nile Express'), findsOneWidget);
      expect(find.byIcon(Icons.route_rounded), findsOneWidget);
    });

    testWidgets('an explicit navigation icon replaces the back arrow', (
      tester,
    ) async {
      await _pumpPushed(
        tester,
        const Scaffold(
          appBar: ClientAppBar(
            title: 'Checkout',
            navigationIcon: Icons.close_rounded,
          ),
        ),
      );

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });

    testWidgets('lays out right-to-left in Arabic without overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        clientTestApp(
          const Scaffold(
            appBar: ClientAppBar(title: 'الرحلات', subtitle: 'إيزي واي'),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(tester.element(find.text('الرحلات'))),
        TextDirection.rtl,
      );
    });
  });
}
