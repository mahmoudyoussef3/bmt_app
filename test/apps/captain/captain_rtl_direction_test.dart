import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_list_group.dart';

/// Which way an icon actually points on screen — not which name it was given.
///
/// Material's directional icons carry `matchTextDirection: true`, and `Icon`
/// wraps those in a horizontal flip when the ambient `Directionality` is RTL
/// (`widgets/icon.dart`). So the glyph's *name* is authored for LTR and the
/// framework mirrors it; in an RTL app `Icons.chevron_left_rounded` reaches the
/// captain's eye pointing **right**.
///
/// That is the trap this file guards. Picking the left-named chevron "because
/// the app is RTL" mirrors an already-correct icon a second time and lands it
/// backwards. These tests assert the rendered direction, so a call site can
/// only pass by being right on a device.
enum _Points { left, right }

/// The direction the glyph is drawn in before any mirroring.
final _glyphDirection = <IconData, _Points>{
  Icons.chevron_left_rounded: _Points.left,
  Icons.chevron_right_rounded: _Points.right,
  Icons.arrow_back_rounded: _Points.left,
  Icons.arrow_back_ios_new_rounded: _Points.left,
  Icons.arrow_forward_rounded: _Points.right,
  Icons.arrow_forward_ios_rounded: _Points.right,
};

_Points _effectiveDirection(IconData data, TextDirection direction) {
  final glyph = _glyphDirection[data];
  if (glyph == null) {
    fail('add ${data.toString()} to _glyphDirection before asserting on it');
  }
  final mirrored = data.matchTextDirection && direction == TextDirection.rtl;
  if (!mirrored) return glyph;
  return glyph == _Points.left ? _Points.right : _Points.left;
}

void main() {
  group('the mirroring rule itself', () {
    test('material directional icons mirror under RTL', () {
      // If this ever changes upstream, every assertion below is re-derived
      // from it rather than from a hand-written expectation.
      expect(Icons.chevron_right_rounded.matchTextDirection, isTrue);
      expect(Icons.arrow_back_rounded.matchTextDirection, isTrue);

      expect(
        _effectiveDirection(Icons.chevron_right_rounded, TextDirection.rtl),
        _Points.left,
        reason: 'the right-named chevron is what shows a left chevron in RTL',
      );
      expect(
        _effectiveDirection(Icons.chevron_left_rounded, TextDirection.rtl),
        _Points.right,
        reason: 'the left-named chevron is double-flipped and lands backwards',
      );
    });

    test('a back arrow points right in RTL, which is what back means there', () {
      expect(
        _effectiveDirection(Icons.arrow_back_rounded, TextDirection.rtl),
        _Points.right,
      );
      expect(
        _effectiveDirection(Icons.arrow_forward_rounded, TextDirection.rtl),
        _Points.left,
      );
    });
  });

  testWidgets('a drill-in row points into the page, not back out of it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CaptainTheme.light(),
        locale: const Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: CaptainListGroup(
              children: [
                CaptainListRow(
                  label: 'سجل الرحلات',
                  showChevron: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chevron = tester.widgetList<Icon>(find.byType(Icon)).firstWhere(
      (icon) => _glyphDirection.containsKey(icon.icon),
      orElse: () => fail('the drill-in row rendered no directional chevron'),
    );

    expect(
      _effectiveDirection(chevron.icon!, TextDirection.rtl),
      _Points.left,
      reason:
          'in an RTL app the next screen arrives from the left, so a drill-in '
          'chevron points left. Pointing right reads as "go back".',
    );
  });

  test('no captain source names a left chevron', () {
    // The three drill-in sites — the shared list row, the trip-history card and
    // the trip-chats entry — were each authored with the left-named chevron
    // "because the app is RTL", which is exactly the double-flip above. This
    // catches the next one at the source rather than on a device.
    final offenders = <String>[];
    final dir = Directory('lib/apps/captain');
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('Icons.chevron_left')) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Icons.chevron_left mirrors to point RIGHT under the captain app\'s '
          'RTL. Use Icons.chevron_right_rounded for a drill-in affordance.',
    );
  });
}
