/// Visual QA harness for the two shared fixes in this pass.
///
/// Not a behaviour test and deliberately not an assertion — run it with
/// `--update-goldens` and *look* at the PNGs it writes to `_captures/`:
///
///     flutter test test/apps/dashboard/core/widgets/directional_and_pagination_visual_capture.dart --update-goldens
///
/// Two things here can only be judged by eye, and neither survives the test
/// font (whose Arabic glyphs are uniform boxes):
///
///  1. **Which way the arrows point.** `expect(icon, chevron_left)` proves the
///     source names the right constant; it cannot prove the operator sees a
///     chevron aimed at the previous page. Material mirrors these under RTL, so
///     only a rendered pixel settles it.
///  2. **The pagination bar's wrap.** It used to overflow at narrow widths;
///     it now reflows onto extra lines. Whether that reflow looks deliberate
///     rather than broken is a judgement call.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/core/theme/app_dark_colors.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/colors.dart';

const _captureFont = 'CaptureArabic';

/// Resolved by walking up from the running test binary until the SDK's font
/// cache appears, rather than hardcoding a path: the test executable is
/// `flutter_tester`, which sits at a different depth per platform and engine
/// build, so counting `.parent`s is a guess that breaks on someone else's
/// machine. Returns null when it cannot be found, and the capture simply keeps
/// the tofu boxes the other harnesses already have.
File? _findMaterialIcons() {
  const suffix = 'artifacts/material_fonts/MaterialIcons-Regular.otf';
  var dir = File(Platform.resolvedExecutable).parent;
  for (var hop = 0; hop < 8; hop++) {
    final candidate = File('${dir.path}/$suffix');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (file.existsSync()) {
      final loader = FontLoader(_captureFont)
        ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      await loader.load();
    }

    // The icon font is *not* loaded by the test binding, so every `Icon`
    // renders as a tofu box — which the other capture harnesses in this repo
    // all silently inherit. For those it costs a little fidelity; for this one
    // it would defeat the entire purpose, since the thing under review is
    // which way an arrow points. Loading it from the SDK's own artifacts is
    // what makes the capture worth looking at.
    final icons = _findMaterialIcons();
    if (icons != null) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
      await loader.load();
    }
  });

  testWidgets('pagination bar — comfortable width', (tester) async {
    await _capture(tester, 'pagination_1_wide', _table(), 900, 260);
  });

  testWidgets('pagination bar — narrow window, where it used to overflow', (
    tester,
  ) async {
    await _capture(tester, 'pagination_2_narrow', _table(), 380, 320);
  });

  testWidgets('pagination bar — narrow window at 1.6× text', (tester) async {
    await _capture(
      tester,
      'pagination_3_narrow_large_text',
      _table(),
      380,
      420,
      textScale: 1.6,
    );
  });

  testWidgets('directional vocabulary under RTL', (tester) async {
    await _capture(tester, 'directional_1_vocabulary', _directions(), 620, 460);
  });
}

Widget _table() => OpsDataTable(
  columns: const [
    OpsColumn('العميل', flex: 2),
    OpsColumn('المسار', flex: 2),
    OpsColumn('المبلغ', numeric: true, sortable: true),
  ],
  rows: const [
    [
      Text('محمد عبد الرحمن السيد'),
      Text('القاهرة — الإسكندرية'),
      Text('٤٥٠ ج.م'),
    ],
    [Text('سارة إبراهيم'), Text('طنطا — القاهرة'), Text('١٢٠ ج.م')],
  ],
  total: 248,
  currentPage: 12,
  pageSize: 12,
  onPageChanged: (_) {},
);

/// Every directional token beside the label of the action it stands for, so a
/// reviewer can read the whole vocabulary at once and see that "رجوع" points
/// back — which in Arabic means it points right.
Widget _directions() => Builder(
  builder: (context) {
    Widget row(IconData icon, String token, String meaning) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 26),
          const SizedBox(width: 16),
          Expanded(child: Text(meaning)),
          Text(
            token,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(DashboardIcons.back, 'back', 'رجوع إلى القائمة'),
        const Divider(),
        row(DashboardIcons.forward, 'forward', 'عرض التفاصيل / متابعة'),
        const Divider(),
        row(DashboardIcons.paginationPrevious, 'paginationPrevious', 'السابق'),
        const Divider(),
        row(DashboardIcons.paginationNext, 'paginationNext', 'التالي'),
        const Divider(),
        row(DashboardIcons.openModule, 'openModule', 'فتح الوحدة'),
        const Divider(),
        row(DashboardIcons.transition, 'transition', 'القاهرة ← الإسكندرية'),
      ],
    );
  },
);

Future<void> _capture(
  WidgetTester tester,
  String name,
  Widget child,
  double width,
  double height, {
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _dashboardDarkWithHostFont(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

/// See the note in `live_ops_visual_capture.dart`: the real dashboard themes
/// build their text theme through google_fonts, which fetches over the network
/// the test binding blocks and throws after the test completes.
ThemeData _dashboardDarkWithHostFont() {
  final scheme = darkColorSchemeFromPalette();
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: _captureFont,
    scaffoldBackgroundColor: AppDarkColors.background,
    canvasColor: AppDarkColors.background,
    cardColor: scheme.surface,
    dividerColor: scheme.outline,
    shadowColor: AppDarkColors.shadow,
    extensions: [AppSurfaceStyle.flat(scheme)],
  );
}
