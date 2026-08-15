/// Visual QA harness for the module header — the one block that opens every
/// dashboard screen, and the one whose height every module pays for.
///
/// Not a test of behaviour and deliberately not part of the suite's assertions:
/// run it with `--update-goldens` and look at the PNGs it writes to
/// `_captures/`.
///
///     flutter test test/apps/dashboard/core/widgets/dashboard_module_header_visual_capture.dart --update-goldens
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/core/theme/app_dark_colors.dart';
import 'package:bmt_app/core/theme/app_light_colors.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

/// Family the captures typeset in, registered in [setUpAll] from a host font
/// that actually carries Arabic. Without it the binding's fallback draws every
/// glyph as a box, which catches an overflow and judges nothing else.
const _captureFont = 'CaptureArabic';

/// The Trips header exactly as that module builds it.
Widget _tripsHeader() => DashboardModuleHeader(
  icon: DashboardIcons.tripsActive,
  title: 'إدارة الرحلات',
  subtitle: 'تابع حركة الرحلات، الإشغال، والطاقم من مساحة عمل واحدة.',
  actions: [
    FilledButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add_rounded),
      label: const Text('رحلة جديدة'),
    ),
  ],
  collapsedSummary: const DashboardSectionSummary(
    items: ['اليوم 0', 'قيد التشغيل 0', 'قادمة 0', 'مكتملة 12', 'فات موعدها 2'],
  ),
  summary: const DashboardKpiGrid(
    children: [
      DashboardKpiCard(
        label: 'رحلات اليوم',
        value: '0',
        icon: Icons.today_rounded,
      ),
      DashboardKpiCard(
        label: 'قيد التشغيل',
        value: '0',
        icon: Icons.directions_bus_filled_rounded,
      ),
      DashboardKpiCard(
        label: 'رحلات قادمة',
        value: '0',
        icon: Icons.upcoming_rounded,
      ),
      DashboardKpiCard(
        label: 'مكتملة',
        value: '12',
        icon: Icons.task_alt_rounded,
      ),
    ],
  ),
);

/// A header carrying both bodies: figures that fold, and a search that cannot.
Widget _ticketsHeader() => DashboardModuleHeader(
  icon: DashboardIcons.ticketsActive,
  title: 'مركز الشكاوى والدعم',
  subtitle: 'راجع شكاوى العملاء، أسندها لموظف، وتابعها حتى الإغلاق.',
  actions: [
    OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('تحديث'),
    ),
  ],
  summary: const Text('الإحصائيات'),
  pinned: DebouncedSearchField(
    hintText: 'ابحث برقم التذكرة أو اسم العميل أو الهاتف...',
    onChanged: (_) {},
  ),
);

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(_captureFont)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  });

  setUp(DashboardSectionStateStore.instance.clear);

  testWidgets('folded — what every module now opens with', (tester) async {
    await _capture(
      tester,
      'module_header_1_folded_dark',
      child: _tripsHeader(),
    );
  });

  testWidgets('open — the summary the operator asked for', (tester) async {
    await _capture(
      tester,
      'module_header_2_open_dark',
      height: 320,
      child: _tripsHeader(),
      open: true,
    );
  });

  testWidgets('folded, light', (tester) async {
    await _capture(
      tester,
      'module_header_3_folded_light',
      child: _tripsHeader(),
      dark: false,
    );
  });

  testWidgets('narrow window stacks the actions under the identity', (
    tester,
  ) async {
    await _capture(
      tester,
      'module_header_4_folded_narrow_dark',
      width: 720,
      height: 260,
      child: _tripsHeader(),
    );
  });

  testWidgets('a pinned control stays on screen while the figures fold', (
    tester,
  ) async {
    await _capture(
      tester,
      'module_header_5_pinned_dark',
      child: _ticketsHeader(),
    );
  });
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required Widget child,
  double width = 1280,
  double height = 220,
  bool dark = true,
  bool open = false,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? _darkWithHostFont() : _lightWithHostFont(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              // mainAxisSize.min so the capture shows the header's real height
              // rather than a card stretched to fill the window — height is the
              // whole point of this harness.
              child: Column(mainAxisSize: MainAxisSize.min, children: [child]),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  if (open) {
    await tester.tap(find.text('الملخص'));
    await tester.pumpAndSettle();
  }

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

/// The real dashboard palette and card surfaces, typeset in a host font.
///
/// `DashboardAppTheme` cannot be used here: it builds its text theme through
/// google_fonts, which tries to fetch the typeface over the network the test
/// binding blocks and then throws after the test completes. Everything this
/// harness judges — surfaces, hairline borders, the primary tint — comes from
/// the same palette functions the real theme uses; only the glyphs differ.
ThemeData _darkWithHostFont() {
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

ThemeData _lightWithHostFont() {
  final scheme = lightColorSchemeFromPalette();
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    fontFamily: _captureFont,
    scaffoldBackgroundColor: AppLightColors.background,
    canvasColor: AppLightColors.background,
    cardColor: scheme.surface,
    dividerColor: scheme.outline,
    shadowColor: AppLightColors.shadow,
    extensions: [AppSurfaceStyle.flat(scheme)],
  );
}
