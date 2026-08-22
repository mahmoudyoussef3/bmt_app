/// Visual QA harness for the trip creation wizard, the trip pricing dialog,
/// and the trip cancellation confirmation — not a behaviour test. Run with
/// `--update-goldens` and *look* at the PNGs in `_captures/`:
///
///     flutter test test/apps/dashboard/features/trips/trip_forms_visual_capture.dart --update-goldens
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/theme/app_dark_colors.dart';
import 'package:bmt_app/core/theme/app_light_colors.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/core/theme/colors.dart';

import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/operation_route.dart';
import 'package:bmt_app/apps/dashboard/features/trips/presentation/widgets/trip_cancellation_dialog.dart';
import 'package:bmt_app/apps/dashboard/features/trips/presentation/widgets/trip_creation_wizard.dart';
import 'package:bmt_app/apps/dashboard/features/trips/presentation/widgets/trip_pricing_editor_dialog.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/domain/entities/trip_driver_option.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_pricing/presentation/cubit/trip_pricing_cubit.dart';

const _captureFont = 'CaptureArabic';

const _vehicle = AssignedVehicle(
  id: 'v-1',
  plateNumber: 'ABC 123',
  vehicleCode: 'VH-01',
  vehicleType: 'Hiace',
  brand: 'Toyota',
  model: 'Hiace',
  capacity: 14,
  status: 'active',
);

const _driver = TripDriverOption(
  id: 'd-1',
  name: 'أحمد محمد',
  phone: '01000000001',
  assignedVehicle: _vehicle,
);

final _route = OperationRoute(
  id: 'r-1',
  name: 'بنها - القاهرة',
  startCity: 'بنها',
  endCity: 'القاهرة',
  duration: 'ساعة',
  distance: '60 كم',
  status: OperationRouteStatus.active,
  stations: const [
    RouteStation(
      id: 'st-1',
      name: 'بنها',
      area: 'القليوبية',
      arrivalOffset: '0',
      departureOffset: '0',
      locationDescription: '',
      notes: '',
      order: 1,
    ),
    RouteStation(
      id: 'st-2',
      name: 'القاهرة',
      area: 'القاهرة',
      arrivalOffset: '60',
      departureOffset: '60',
      locationDescription: '',
      notes: '',
      order: 2,
    ),
  ],
  notes: const [],
);

final _trip = OperationTrip(
  id: 't-1',
  routeId: 'r-1',
  route: 'بنها - القاهرة',
  routePoints: [
    TripRoutePoint(id: 'st-1', name: 'بنها', order: 1),
    TripRoutePoint(id: 'st-2', name: 'القاهرة', order: 2),
  ],
  driverId: 'd-1',
  driver: 'أحمد محمد',
  vehicleId: 'v-1',
  vehicle: 'ABC 123',
  date: '2026-08-25',
  departure: '08:00:00',
  arrival: '09:00:00',
  status: OperationTripStatus.openForBooking,
  capacity: 14,
  ticketPrice: 60,
  currency: 'ج.م',
  seats: const [],
  passengers: const [
    TripPassenger(
      id: 'p-1',
      name: 'راكب 1',
      phone: '',
      seat: '1',
      pickup: 'بنها',
      dropoff: 'القاهرة',
      paymentMethod: 'cash',
      status: 'confirmed',
    ),
    TripPassenger(
      id: 'p-2',
      name: 'راكب 2',
      phone: '',
      seat: '2',
      pickup: 'بنها',
      dropoff: 'القاهرة',
      paymentMethod: 'cash',
      status: 'confirmed',
    ),
  ],
  events: const [],
  notes: const [],
);

class _FakeTripPricingCubit extends Cubit<TripPricingState>
    implements TripPricingCubit {
  _FakeTripPricingCubit() : super(const TripPricingInitial());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(_captureFont)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  });

  group('trip creation wizard', () {
    testWidgets('blank, light', (tester) async {
      await _captureWizard(tester, 'trip_wizard_1_blank_light', dark: false);
    });

    testWidgets('blank, dark (sanity check)', (tester) async {
      await _captureWizard(tester, 'trip_wizard_2_blank_dark', dark: true);
    });

    testWidgets('a half-filled package row shows exactly what is missing', (
      tester,
    ) async {
      await _captureWizard(
        tester,
        'trip_wizard_3_package_row_errors_light',
        dark: false,
        afterPump: (tester) async {
          // Route + driver, so the fare panel is on screen.
          await tester.tap(find.byType(DropdownButtonFormField<String>).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text(_route.name).last);
          await tester.pumpAndSettle();
          await tester.tap(find.byType(DropdownButtonFormField<String>).last);
          await tester.pumpAndSettle();
          await tester.tap(find.textContaining(_driver.name).last);
          await tester.pumpAndSettle();

          // Start a new trip-only package and fill in only the name.
          await tester.tap(find.text('باقة جديدة لهذه الرحلة'));
          await tester.pumpAndSettle();
          final nameField = find.byWidgetPredicate(
            (w) => w is TextField && w.decoration?.labelText == 'اسم الباقة',
          );
          await tester.enterText(nameField, 'باقة تجريبية');
          await tester.pump();
          await tester.ensureVisible(nameField);
          await tester.pumpAndSettle();
        },
      );
    });
  });

  group('trip pricing dialog', () {
    testWidgets('a new pricing row, light', (tester) async {
      await _capturePricingDialog(tester, 'trip_pricing_1_new_light');
    });

    testWidgets('submitted with no ticket price, light', (tester) async {
      await _capturePricingDialog(
        tester,
        'trip_pricing_2_validation_light',
        afterPump: (tester) async {
          await tester.tap(find.text('حفظ'));
          await tester.pumpAndSettle();
        },
      );
    });
  });

  group('trip cancellation — a destructive confirmation dialog', () {
    testWidgets('with active passengers, light', (tester) async {
      await _captureCancellation(
        tester,
        'trip_cancel_1_light',
        dark: false,
      );
    });

    testWidgets('a required reason left blank, light', (tester) async {
      await _captureCancellation(
        tester,
        'trip_cancel_2_validation_light',
        dark: false,
        reasonRequired: true,
        afterPump: (tester) async {
          await tester.tap(find.text('تأكيد الإلغاء'));
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('dark (sanity check)', (tester) async {
      await _captureCancellation(tester, 'trip_cancel_3_dark', dark: true);
    });
  });
}

Future<void> _captureWizard(
  WidgetTester tester,
  String name, {
  required bool dark,
  Future<void> Function(WidgetTester tester)? afterPump,
}) async {
  tester.view.physicalSize = const Size(1400, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _themeWithHostFont(dark: dark),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(key: key, child: child!),
      ),
      home: Scaffold(
        body: TripCreationWizard(
          routes: [_route],
          drivers: const [_driver],
          packages: const [],
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  if (afterPump != null) await afterPump(tester);

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

Future<void> _capturePricingDialog(
  WidgetTester tester,
  String name, {
  Future<void> Function(WidgetTester tester)? afterPump,
}) async {
  tester.view.physicalSize = const Size(900, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final cubit = _FakeTripPricingCubit();
  addTearDown(cubit.close);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _themeWithHostFont(dark: false),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(key: key, child: child!),
      ),
      home: BlocProvider<TripPricingCubit>.value(
        value: cubit,
        child: Scaffold(
          body: Center(
            child: TripPricingEditorDialog(trip: _trip, packages: const []),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  if (afterPump != null) await afterPump(tester);

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

Future<void> _captureCancellation(
  WidgetTester tester,
  String name, {
  required bool dark,
  bool reasonRequired = false,
  Future<void> Function(WidgetTester tester)? afterPump,
}) async {
  tester.view.physicalSize = const Size(900, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _themeWithHostFont(dark: dark),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(key: key, child: child!),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showTripCancellationDialog(
                context,
                trip: _trip,
                reasonRequired: reasonRequired,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  if (afterPump != null) await afterPump(tester);

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

ThemeData _themeWithHostFont({required bool dark}) {
  final scheme = dark
      ? darkColorSchemeFromPalette()
      : lightColorSchemeFromPalette();
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    fontFamily: _captureFont,
    scaffoldBackgroundColor: dark
        ? AppDarkColors.background
        : AppLightColors.background,
    canvasColor: dark ? AppDarkColors.background : AppLightColors.background,
    cardColor: scheme.surface,
    dividerColor: scheme.outline,
    shadowColor: dark ? AppDarkColors.shadow : AppLightColors.shadow,
    extensions: [
      dark ? AppSurfaceStyle.flat(scheme) : AppSurfaceStyle.dashboardLight(scheme),
    ],
  );
}
