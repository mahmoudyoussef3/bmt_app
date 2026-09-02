/// Visual QA harness for طلبات الكباتن — the captain joining queue — in both
/// themes.
///
/// The module was rebuilt onto the console's shared list-module shape (header
/// with a foldable KPI strip → [DashboardFilterBar] → results header → table,
/// falling back to cards below [kDashboardTableBreakpoint]), and none of that
/// layout, the queue-pill strip, or the EWT warm-paper card treatment can be
/// judged from code.
///
/// Not a test of behaviour and deliberately not part of the suite's
/// assertions: run it with `--update-goldens` and look at the PNGs it writes
/// to `_captures/`.
///
///     flutter test test/apps/dashboard/features/captain_requests/captain_requests_visual_capture.dart --update-goldens
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_color_scheme.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_dark_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_light_colors.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/domain/entities/captain_request.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/presentation/cubit/captain_requests_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/presentation/cubit/captain_requests_state.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/presentation/screens/captain_requests_screen.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';

const _captureFont = 'CaptureArabic';

/// Fixed so «منذ ٣ أيام» and the average-response figure land in the same
/// bucket on every run.
final DateTime _now = DateTime(2026, 9, 1, 10);

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (file.existsSync()) {
      final loader = FontLoader(_captureFont)
        ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      await loader.load();
    }

    // Registers the real MaterialIcons glyphs, so icons render as themselves
    // instead of tofu boxes. `flutter test` sets FLUTTER_ROOT for its child
    // process, which is the only portable way to find the SDK's bundled font.
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot == null) return;
    final iconFont = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (!iconFont.existsSync()) return;
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(iconFont.readAsBytesSync())));
    await iconLoader.load();
  });

  setUp(DashboardSectionStateStore.instance.clear);
  tearDown(DashboardSectionStateStore.instance.clear);

  testWidgets('the pending queue, light', (tester) async {
    await _capture(tester, 'captain_requests_1_pending_light', dark: false);
  });

  testWidgets('the pending queue, dark', (tester) async {
    await _capture(tester, 'captain_requests_2_pending_dark', dark: true);
  });

  testWidgets('every request — the full table', (tester) async {
    await _capture(
      tester,
      'captain_requests_3_all_light',
      dark: false,
      state: _loaded(filterStatus: null),
    );
  });

  testWidgets('narrow — the card layout', (tester) async {
    await _capture(
      tester,
      'captain_requests_4_narrow_light',
      dark: false,
      width: 900,
      height: 1500,
      state: _loaded(filterStatus: null),
    );
  });

  testWidgets('an office nobody has applied to yet', (tester) async {
    await _capture(
      tester,
      'captain_requests_5_empty_light',
      dark: false,
      height: 900,
      state: const CaptainRequestsLoaded(requests: []),
    );
  });
}

CaptainRequest _request({
  required String id,
  required String name,
  required String phone,
  required CaptainRequestStatus status,
  required int daysAgo,
  String? note,
  String? rejectionReason,
  int? decidedAfterHours,
}) {
  final createdAt = _now.subtract(Duration(days: daysAgo));
  return CaptainRequest(
    id: id,
    fullName: name,
    phone: phone,
    status: status,
    createdAt: createdAt,
    note: note,
    rejectionReason: rejectionReason,
    reviewedAt: decidedAfterHours == null
        ? null
        : createdAt.add(Duration(hours: decidedAfterHours)),
  );
}

CaptainRequestsLoaded _loaded({
  CaptainRequestStatus? filterStatus = CaptainRequestStatus.pending,
}) {
  return CaptainRequestsLoaded(
    filterStatus: filterStatus,
    requests: [
      _request(
        id: '1',
        name: 'سيد عبد الحميد',
        phone: '01007771122',
        status: CaptainRequestStatus.pending,
        daysAgo: 0,
        note: 'خبرة ٨ سنوات في النقل الجماعي، رخصة مهنية سارية.',
      ),
      _request(
        id: '2',
        name: 'وليد جمعة',
        phone: '01223334455',
        status: CaptainRequestStatus.pending,
        daysAgo: 1,
        note: 'عملت على خط بنها — القرية الذكية سابقاً.',
      ),
      _request(
        id: '3',
        name: 'مصطفى فؤاد',
        phone: '01109998877',
        status: CaptainRequestStatus.approved,
        daysAgo: 62,
        decidedAfterHours: 5,
        note: 'خبرة ١١ سنة.',
      ),
      _request(
        id: '4',
        name: 'كريم نصار',
        phone: '01061112233',
        status: CaptainRequestStatus.approved,
        daysAgo: 180,
        decidedAfterHours: 9,
      ),
      _request(
        id: '5',
        name: 'رمضان السيد',
        phone: '01284445566',
        status: CaptainRequestStatus.rejected,
        daysAgo: 21,
        decidedAfterHours: 4,
        rejectionReason: 'الرخصة خاصة وليست مهنية.',
      ),
      _request(
        id: '6',
        name: 'أحمد حسن',
        phone: '01012223344',
        status: CaptainRequestStatus.approved,
        daysAgo: 300,
        decidedAfterHours: 7,
      ),
      _request(
        id: '7',
        name: 'طه منصور',
        phone: '01095556677',
        status: CaptainRequestStatus.rejected,
        daysAgo: 30,
        decidedAfterHours: 6,
        rejectionReason: 'الرخصة منتهية منذ أكثر من عام.',
      ),
    ],
  );
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required bool dark,
  double width = 1440,
  double height = 1400,
  CaptainRequestsLoaded? state,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final cubit = _StaticCubit(state ?? _loaded());
  addTearDown(cubit.close);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _themeWithHostFont(dark: dark),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: BlocProvider<CaptainRequestsCubit>.value(
              value: cubit,
              child: const CaptainRequestsScreen(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

/// [DashboardAppTheme] itself builds its text theme through
/// `GoogleFonts.cairoTextTheme()`, which the test binding's blocked network
/// turns into a hard failure — so this hand-builds a [ThemeData] from the same
/// palette and [AppSurfaceStyle.ewt] card treatment the real theme uses, with
/// the host font substituted directly. The palette and card language are the
/// real ones; only the glyphs differ.
ThemeData _themeWithHostFont({required bool dark}) {
  final scheme = dark
      ? dashboardDarkColorScheme()
      : dashboardLightColorScheme();
  final background = dark
      ? DashboardDarkColors.background
      : DashboardLightColors.background;
  final shadow = dark
      ? DashboardDarkColors.shadow
      : DashboardLightColors.shadow;
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    fontFamily: _captureFont,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    cardColor: scheme.surface,
    dividerColor: scheme.outline,
    shadowColor: shadow,
    extensions: [AppSurfaceStyle.ewt(scheme)],
  );
}

class _StaticCubit extends Cubit<CaptainRequestsState>
    implements CaptainRequestsCubit {
  _StaticCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
