import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/widgets/directional_icon.dart';

/// Counts how many times the glyph is horizontally mirrored on its way to the
/// screen. Flutter's own `matchTextDirection` handling contributes one (from
/// inside [Icon]); anything [DirectionalIcon] adds sits above it.
int _horizontalFlips(WidgetTester tester) {
  return tester
      .widgetList<Transform>(find.byType(Transform))
      .where((t) => t.transform.storage[0] < 0)
      .length;
}

Widget _host({required TextDirection direction, required Widget child}) {
  return Directionality(
    textDirection: direction,
    child: Center(child: child),
  );
}

/// A directional glyph that does *not* declare `matchTextDirection`, so Flutter
/// will not mirror it and [DirectionalIcon] still has work to do. Built by hand
/// because essentially every directional glyph Material ships already carries
/// the flag.
const _unflaggedArrow = IconData(0xe5c4, fontFamily: 'MaterialIcons');

void main() {
  group('DirectionalIcon', () {
    testWidgets('does not re-mirror a glyph Flutter already mirrors under RTL', (
      tester,
    ) async {
      // arrow_back_rounded declares matchTextDirection, so Icon flips it on its
      // own. Flipping again cancels that out and leaves the back arrow pointing
      // the wrong way for an Arabic reader.
      expect(Icons.arrow_back_rounded.matchTextDirection, isTrue);

      await tester.pumpWidget(
        _host(
          direction: TextDirection.rtl,
          child: const DirectionalIcon(Icons.arrow_back_rounded),
        ),
      );

      expect(
        _horizontalFlips(tester),
        1,
        reason: 'exactly one mirror, contributed by Icon itself',
      );
    });

    testWidgets('mirrors a directional glyph Flutter leaves alone', (
      tester,
    ) async {
      expect(_unflaggedArrow.matchTextDirection, isFalse);

      await tester.pumpWidget(
        _host(
          direction: TextDirection.rtl,
          child: const DirectionalIcon(_unflaggedArrow),
        ),
      );

      expect(_horizontalFlips(tester), 1);
    });

    testWidgets('never mirrors anything under LTR', (tester) async {
      await tester.pumpWidget(
        _host(
          direction: TextDirection.ltr,
          child: const Column(
            children: [
              DirectionalIcon(Icons.arrow_back_rounded),
              DirectionalIcon(_unflaggedArrow),
            ],
          ),
        ),
      );

      expect(_horizontalFlips(tester), 0);
    });
  });
}
