import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/routes/presentation/widgets/route_timeline_node.dart';

/// The stop names in the order they actually appear on screen, read the way the
/// [direction] says to read them (right-to-left in Arabic).
///
/// A chain is one bidi paragraph however many `TextSpan`s it is built from, so
/// this measures the rendered boxes rather than inspecting the spans.
Future<List<String>> _visualOrder(
  WidgetTester tester,
  List<String> stops,
  TextDirection direction,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: RouteDirectionChain(stops: stops)),
      ),
    ),
  );

  final richText = tester.widget<RichText>(find.byType(RichText).first);
  final painter = TextPainter(text: richText.text, textDirection: direction)
    ..layout(maxWidth: 3000);
  final label = richText.text.toPlainText();

  final placed = <(String, double)>[];
  for (final stop in stops) {
    final start = label.indexOf(stop);
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: start + stop.length),
    );
    final centers = boxes.map((box) => (box.left + box.right) / 2);
    placed.add((stop, centers.reduce((a, b) => a + b) / boxes.length));
  }

  placed.sort(
    (a, b) => direction == TextDirection.rtl
        ? b.$2.compareTo(a.$2)
        : a.$2.compareTo(b.$2),
  );
  return placed.map((entry) => entry.$1).toList();
}

void main() {
  // The all-Latin chain is the one that regressed: the geocoder names most
  // Egyptian stops in Latin script, and such a chain resolves LTR under UAX#9
  // rule N1 — so in the Arabic console it used to lay itself out end-to-start
  // while an Arabic-named route beside it read correctly.
  const chains = <(String, List<String>)>[
    ('latin', ['New Cairo', 'Adly Mansour', 'Zefta']),
    ('arabic', ['بنها', 'شبين القناطر', 'القاهرة']),
    ('mixed', ['New Cairo', 'العاشر من رمضان', 'شبرا بخوم']),
  ];

  for (final (name, stops) in chains) {
    testWidgets('RouteDirectionChain runs origin-first · $name', (
      tester,
    ) async {
      expect(
        await _visualOrder(tester, stops, TextDirection.rtl),
        stops,
        reason: 'the console showed this route running backwards',
      );
    });
  }
}
