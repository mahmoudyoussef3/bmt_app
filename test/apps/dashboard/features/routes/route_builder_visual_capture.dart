/// Visual QA harness for the route builder screen — not a behaviour test.
/// Run with `--update-goldens` and *look* at the PNGs in `_captures/`:
///
///     flutter test test/apps/dashboard/features/routes/route_builder_visual_capture.dart --update-goldens
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/geo/geo_service.dart';
import 'package:bmt_app/core/theme/app_dark_colors.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/colors.dart';

import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/route_draft.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/get_route_geometry_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/cubit/route_builder_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/routes/presentation/widgets/route_builder/route_builder_view.dart';

const _captureFont = 'CaptureArabic';

class _DisabledGeoService implements GeoService {
  @override
  bool get enabled => false;

  @override
  Future<List<GeoPlace>> autocomplete(String query, {GeoPoint? focus}) async =>
      const [];

  @override
  Future<RouteGeometry> directions(List<GeoPoint> orderedPoints) async =>
      throw UnimplementedError();
}

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(_captureFont)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();

    final getIt = GetIt.instance;
    if (!getIt.isRegistered<GetRouteGeometryUseCase>()) {
      getIt.registerLazySingleton<GetRouteGeometryUseCase>(
        () => GetRouteGeometryUseCase(_DisabledGeoService()),
      );
    }
    if (!getIt.isRegistered<RouteBuilderCubit>()) {
      getIt.registerFactory<RouteBuilderCubit>(
        () => RouteBuilderCubit(getIt<GetRouteGeometryUseCase>()),
      );
    }
  });

  testWidgets('blank draft — a fresh route with nothing filled in', (
    tester,
  ) async {
    await _capture(
      tester,
      'route_builder_1_blank',
      draft: RouteDraft.blank(suggestedCode: 'RT-03'),
      width: 1280,
      height: 1000,
    );
  });

  testWidgets('mid-journey — named endpoints and one waypoint', (tester) async {
    final draft = RouteDraft(
      id: '',
      suggestedCode: 'RT-03',
      stops: [
        RouteStopDraft(
          key: RouteStopDraft.freshKey(),
          name: 'بنها',
          area: 'القليوبية',
        ),
        RouteStopDraft(
          key: RouteStopDraft.freshKey(),
          name: 'شبين القناطر',
          area: 'القليوبية',
          dwellMinutes: 5,
        ),
        RouteStopDraft(key: RouteStopDraft.freshKey(), name: 'القاهرة'),
      ],
    );
    await _capture(
      tester,
      'route_builder_2_midjourney',
      draft: draft,
      width: 1280,
      height: 1300,
    );
  });

  testWidgets('editing an existing route — full details, code and name set', (
    tester,
  ) async {
    final draft = RouteDraft(
      id: 'route-1',
      nameOverride: 'بنها - القاهرة',
      codeOverride: 'RT-07',
      suggestedCode: 'RT-07',
      distance: '42 كم',
      duration: '1 س 10 د',
      stops: [
        RouteStopDraft(
          key: RouteStopDraft.freshKey(),
          name: 'بنها',
          area: 'القليوبية',
        ),
        RouteStopDraft(
          key: RouteStopDraft.freshKey(),
          name: 'شبين القناطر',
          area: 'القليوبية',
          dwellMinutes: 5,
        ),
        RouteStopDraft(
          key: RouteStopDraft.freshKey(),
          name: 'القاهرة',
          area: 'القاهرة',
        ),
      ],
    );
    await _capture(
      tester,
      'route_builder_3_editing',
      draft: draft,
      width: 1280,
      height: 1300,
    );
  });

  testWidgets('بيانات المسار opened — prefix icons on every field', (
    tester,
  ) async {
    final draft = RouteDraft(
      id: '',
      suggestedCode: 'RT-03',
      stops: [
        RouteStopDraft(key: RouteStopDraft.freshKey(), name: 'بنها'),
        RouteStopDraft(key: RouteStopDraft.freshKey(), name: 'القاهرة'),
      ],
    );
    await _capture(
      tester,
      'route_builder_4_details_open',
      draft: draft,
      width: 1280,
      height: 1100,
      afterPump: (tester) async {
        await tester.tap(find.text('بيانات المسار'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('add-stop dialog — the new حفظ والتالي action', (tester) async {
    final draft = RouteDraft(
      id: '',
      suggestedCode: 'RT-03',
      stops: [
        RouteStopDraft(key: RouteStopDraft.freshKey(), name: 'بنها'),
        RouteStopDraft(key: RouteStopDraft.freshKey(), name: 'القاهرة'),
      ],
    );
    await _capture(
      tester,
      'route_builder_5_add_stop_dialog',
      draft: draft,
      width: 1280,
      height: 1000,
      afterPump: (tester) async {
        await tester.tap(find.text('إضافة نقطة').first);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'شبين القناطر');
        await tester.pump();
      },
    );
  });

  testWidgets('add-stop dialog — untouched, before a name is typed', (
    tester,
  ) async {
    final draft = RouteDraft(
      id: '',
      suggestedCode: 'RT-03',
      stops: [
        RouteStopDraft(key: RouteStopDraft.freshKey(), name: 'بنها'),
        RouteStopDraft(key: RouteStopDraft.freshKey(), name: 'القاهرة'),
      ],
    );
    await _capture(
      tester,
      'route_builder_6_add_stop_dialog_empty',
      draft: draft,
      width: 1280,
      height: 1000,
      afterPump: (tester) async {
        await tester.tap(find.text('إضافة نقطة').first);
        await tester.pumpAndSettle();
      },
    );
  });
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required RouteDraft draft,
  required double width,
  required double height,
  Future<void> Function(WidgetTester tester)? afterPump,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // The RepaintBoundary sits in MaterialApp.builder, above the Navigator, so
  // it captures dialogs (separate Overlay entries) too — not just `home`.
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _dashboardDarkWithHostFont(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(key: key, child: child!),
      ),
      home: Scaffold(
        body: RouteBuilderView(
          route: null,
          draft: draft,
          existingCodes: const ['RT-01', 'RT-02'],
          saving: false,
          saveError: '',
          onCancel: () {},
          onSave: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  if (afterPump != null) await afterPump(tester);

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

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
