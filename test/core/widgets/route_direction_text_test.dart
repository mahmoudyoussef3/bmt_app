import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/widgets/route_direction_text.dart';

/// Where a substring actually lands on screen, in device pixels from the left.
///
/// The assertions below are about *layout*, not about the characters in the
/// string: a direction label that reads correctly is one where the arrow ends
/// up pointing at the destination after the bidi algorithm has run. Comparing
/// the composed string against an expected string would pass while the screen
/// showed the trip backwards, which is exactly the bug this guards.
double _centerX(String label, String needle, TextDirection direction) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: const TextStyle(fontSize: 14)),
    textDirection: direction,
  )..layout(maxWidth: 3000);
  final start = label.indexOf(needle);
  expect(start, isNonNegative, reason: '"$needle" missing from "$label"');
  final boxes = painter.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + needle.length),
  );
  final centers = boxes.map((box) => (box.left + box.right) / 2);
  return centers.reduce((a, b) => a + b) / boxes.length;
}

/// True when the arrow glyph in [label] points at [destination] rather than
/// back at [origin].
bool _pointsAtDestination(
  String label,
  String origin,
  String destination,
  TextDirection direction,
) {
  final originX = _centerX(label, origin, direction);
  final destinationX = _centerX(label, destination, direction);
  return label.contains('→') // rightwards
      ? destinationX > originX
      : destinationX < originX;
}

void main() {
  // Every combination that reaches a real screen. The Latin pair is not
  // decoration: the geocoder returns Latin names for most Egyptian places, and
  // an Arabic-only fixture set makes this whole bug invisible.
  const pairs = <(String, String, String)>[
    ('latin', 'New Cairo', 'Zefta'),
    ('arabic', 'القاهرة الجديدة', 'زفتى'),
    ('latin origin, arabic destination', 'New Cairo', 'شبرا بخوم'),
    ('arabic origin, latin destination', 'شبرا بخوم', 'New Cairo'),
  ];

  group('routeDirectionLabel points at the destination', () {
    for (final direction in TextDirection.values) {
      for (final (name, origin, destination) in pairs) {
        test('$name · ${direction.name}', () {
          final label = routeDirectionLabel(
            origin,
            destination,
            direction: direction,
          );
          expect(
            _pointsAtDestination(label, origin, destination, direction),
            isTrue,
            reason:
                'the arrow points back at the origin — the label announces '
                'the return leg of the trip that was actually saved',
          );
        });
      }
    }
  });

  group('a hand-rolled label is what this replaces', () {
    // Pinned so the fix cannot be quietly reverted to string interpolation:
    // three of these four render backwards.
    for (final (name, origin, destination) in pairs.skip(1)) {
      test('$name · rtl · reverses without isolates', () {
        expect(
          _pointsAtDestination(
            '$origin → $destination',
            origin,
            destination,
            TextDirection.rtl,
          ),
          isFalse,
        );
      });
    }
  });

  group('degenerate endpoints', () {
    test('an empty endpoint drops the arrow rather than dangling it', () {
      const rtl = TextDirection.rtl;
      expect(routeDirectionLabel('', '', direction: rtl), isEmpty);
      expect(
        routeDirectionLabel('Zefta', '', direction: rtl),
        contains('Zefta'),
      );
      expect(
        routeDirectionLabel('Zefta', '', direction: rtl),
        isNot(contains('←')),
      );
      expect(
        routeDirectionLabel('', 'Zefta', direction: rtl),
        isNot(contains('←')),
      );
    });

    test('isolatedPlaceName leaves nothing behind for a blank name', () {
      expect(isolatedPlaceName('   '), isEmpty);
    });
  });

  group('RouteDirectionText renders against the ambient direction', () {
    for (final direction in TextDirection.values) {
      testWidgets('${direction.name} picks the matching arrow', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: direction,
            child: const RouteDirectionText(
              origin: 'New Cairo',
              destination: 'Zefta',
            ),
          ),
        );
        final text = tester.widget<Text>(find.byType(Text)).data!;
        expect(text, contains(direction == TextDirection.rtl ? '←' : '→'));
        expect(
          _pointsAtDestination(text, 'New Cairo', 'Zefta', direction),
          isTrue,
        );
      });

      testWidgets('${direction.name} styles the arrow apart without '
          'disturbing the layout', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: direction,
            child: const RouteDirectionText(
              origin: 'New Cairo',
              destination: 'شبرا بخوم',
              connectorStyle: TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        );
        // Styling the connector must not change a character: same string, so
        // the same bidi resolution as the plain form.
        final rendered = tester
            .widget<Text>(find.byType(Text))
            .textSpan!
            .toPlainText();
        expect(
          rendered,
          routeDirectionLabel('New Cairo', 'شبرا بخوم', direction: direction),
        );
        expect(
          _pointsAtDestination(rendered, 'New Cairo', 'شبرا بخوم', direction),
          isTrue,
        );
      });
    }
  });
}
