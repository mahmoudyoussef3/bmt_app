/// Visual QA harness for the Live Operations Center's *quiet* states — the
/// board with nothing on it, which is what an operator sees most nights and the
/// hardest state to judge from code.
///
/// Not a test of behaviour and deliberately not part of the suite's assertions:
/// run it with `--update-goldens` and look at the PNGs it writes to
/// `_captures/`.
///
///     flutter test test/apps/dashboard/features/live_ops/live_ops_visual_capture.dart --update-goldens
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/theme/app_dark_colors.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/fleet_feed.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/live_ops_snapshot.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/trip_incident.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/repositories/live_ops_repository.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/usecases/live_ops_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/cubit/live_ops_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/screens/live_ops_screen.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/widgets/incident_queue_section.dart';

/// Family the captures typeset in, registered in [setUpAll] from a host font
/// that actually carries Arabic. Without it the test binding's fallback draws
/// every glyph as a box, which is fine for catching an overflow and useless for
/// judging a screen whose content is all Arabic.
const _captureFont = 'CaptureArabic';

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(_captureFont)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  });

  testWidgets('quiet board — the all-clear replaces both empty panels', (
    tester,
  ) async {
    await _capture(
      tester,
      'live_ops_1_quiet_dark',
      child: const LiveOpsScreen(),
      width: 1280,
      height: 720,
    );
  });

  testWidgets('quiet board, narrow window', (tester) async {
    await _capture(
      tester,
      'live_ops_2_quiet_narrow_dark',
      child: const LiveOpsScreen(),
      width: 760,
      height: 800,
    );
  });

  testWidgets('cleared incident queue inside its panel', (tester) async {
    await _capture(
      tester,
      'live_ops_3_incidents_cleared_dark',
      width: 560,
      height: 300,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DashboardPanel(
          sectionId: DashboardSectionIds.liveOpsIncidents,
          icon: Icons.report_rounded,
          title: 'البلاغات المفتوحة',
          child: IncidentQueueSection(
            incidents: const [],
            now: DateTime.now(),
            onAction: (_, _, {note}) async => null,
          ),
        ),
      ),
    );
  });

  // The half-quiet board: one side has work, so both panels stay and each empty
  // side has to hold its own next to a populated one.
  testWidgets('no trips, one open report', (tester) async {
    await _capture(
      tester,
      'live_ops_4_trips_empty_dark',
      width: 560,
      height: 380,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DashboardPanel(
          sectionId: DashboardSectionIds.liveOpsTrips,
          icon: Icons.route_rounded,
          title: 'الرحلات على الطريق',
          child: const DashboardEmptyState(
            icon: DashboardIcons.trips,
            title: 'لا توجد رحلات على الطريق حالياً',
            message:
                'ستظهر الرحلات هنا فور أن يبدأ الكباتن تنفيذها، مع تتبّع مباشر لكل مركبة.',
          ),
        ),
      ),
    );
  });
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required Widget child,
  required double width,
  required double height,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final cubit = LiveOpsCubit(
    getSnapshot: const GetLiveOpsSnapshotUseCase(_QuietRepo()),
    watch: const WatchLiveOpsUseCase(_QuietRepo()),
    updateIncident: const UpdateIncidentStatusUseCase(_QuietRepo()),
  );
  addTearDown(cubit.close);
  await cubit.load();

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _dashboardDarkWithHostFont(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: BlocProvider.value(value: cubit, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

/// The real dashboard dark palette and card surfaces, typeset in a host font.
///
/// Neither `DashboardAppTheme.dark()` nor `AppTheme.darkTheme()` can be used
/// here: both build their text theme through google_fonts, which tries to fetch
/// the typeface over the network the test binding blocks and then throws after
/// the test completes. Everything this harness is meant to judge — the slate
/// surfaces, the hairline card borders, the status tints — comes from the same
/// palette functions the real theme uses; only the glyph shapes differ.
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

/// Nothing running, nothing reported, read a moment ago — so the freshness line
/// shows what it shows on a live console rather than a fossil date.
class _QuietRepo implements LiveOpsRepository {
  const _QuietRepo();

  @override
  Future<LiveOpsSnapshot> getSnapshot() async =>
      LiveOpsSnapshot.empty(DateTime.now());

  @override
  Stream<void> watchChanges() => const Stream.empty();

  @override
  Stream<FleetFeedEvent> watchFleetFixes() => const Stream.empty();

  @override
  Future<Map<String, LiveFix>> fetchLatestFixes() async => const {};

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus next,
    String? note,
  }) async {}
}
