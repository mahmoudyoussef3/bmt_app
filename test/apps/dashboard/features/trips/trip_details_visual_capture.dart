/// Visual QA harness for the trip details workspace (`TripDetailsWorkspace`)
/// — not a behaviour test. Phase 3 reorganised the Overview tab into clearly
/// labelled route/vehicle-driver/passenger-capacity/financial sections, made
/// the publish blocker visible without hovering, and gave each passenger row
/// a payment-status chip. None of that can be judged from code.
///
/// Run with `--update-goldens` and *look* at the PNGs in `_captures/`:
///
///     flutter test test/apps/dashboard/features/trips/trip_details_visual_capture.dart --update-goldens
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

import 'package:bmt_app/apps/dashboard/features/trips/presentation/screens/trips_screen.dart';
import 'package:bmt_app/apps/dashboard/features/trips/presentation/widgets/trip_row_card.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/repositories/trips_repository.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/usecases/trip_management_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trip_details_cubit.dart';

const _captureFont = 'CaptureArabic';

/// A `TripsRepository` that only answers `watchTripChanges` (needed so
/// `TripDetailsCubit.showDetails` can subscribe without throwing). Nothing
/// else is exercised by a static capture — no button is tapped — so every
/// other member falls through to `noSuchMethod`.
class _StubTripsRepository implements TripsRepository {
  const _StubTripsRepository();

  @override
  Stream<void> watchTripChanges(String tripId) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TripDetailsCubit _cubit() {
  const repo = _StubTripsRepository();
  return TripDetailsCubit(
    getTripDetails: const GetTripDetailsUseCase(repo),
    updateTripStatus: const UpdateTripStatusUseCase(repo),
    updateTripInfo: const UpdateTripInfoUseCase(repo),
    cancelTrip: const CancelTripUseCase(repo),
    closeStaleTrip: const CloseStaleTripUseCase(repo),
    watchTripDetails: const WatchTripDetailsUseCase(repo),
  );
}

const _routePoints = [
  TripRoutePoint(id: 'p-1', name: 'بنها', order: 1),
  TripRoutePoint(id: 'p-2', name: 'شبرا الخيمة', order: 2),
  TripRoutePoint(id: 'p-3', name: 'القاهرة - رمسيس', order: 3),
];

/// A fully staffed, partly-booked trip — the common case an owner opens
/// mid-day: some seats paid, some reserved, one subscription rider, one
/// blocked, a healthy chunk still available.
final _richTrip = OperationTrip(
  id: 'trip-1',
  routeId: 'route-1',
  route: 'بنها - القاهرة',
  routePoints: _routePoints,
  driverId: 'driver-1',
  driver: 'أحمد حسن',
  vehicleId: 'vehicle-1',
  vehicle: 'هايس (ق س أ 1234)',
  vehicleType: 'hiace',
  date: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
  departure: '08:30',
  arrival: '10:15',
  status: OperationTripStatus.openForBooking,
  capacity: 10,
  ticketPrice: 75,
  seats: [
    for (var i = 0; i < 4; i++)
      TripSeat(
        id: 'seat-paid-$i',
        label: 'م${i + 1}',
        row: 0,
        column: i,
        state: TripSeatState.paid,
      ),
    for (var i = 0; i < 2; i++)
      TripSeat(
        id: 'seat-reserved-$i',
        label: 'م${i + 5}',
        row: 1,
        column: i,
        state: TripSeatState.reserved,
      ),
    const TripSeat(
      id: 'seat-sub-1',
      label: 'م7',
      row: 1,
      column: 2,
      state: TripSeatState.subscription,
    ),
    const TripSeat(
      id: 'seat-blocked-1',
      label: 'م8',
      row: 1,
      column: 3,
      state: TripSeatState.blocked,
    ),
    for (var i = 0; i < 2; i++)
      TripSeat(
        id: 'seat-avail-$i',
        label: 'م${i + 9}',
        row: 2,
        column: i,
        state: TripSeatState.available,
      ),
  ],
  passengers: const [
    TripPassenger(
      id: 'pax-1',
      name: 'محمد علي',
      phone: '01000000001',
      seat: 'م1',
      pickup: 'بنها',
      dropoff: 'القاهرة - رمسيس',
      paymentMethod: 'كاش',
      status: 'paid',
    ),
    TripPassenger(
      id: 'pax-2',
      name: 'سارة يوسف',
      phone: '01000000002',
      seat: 'م5',
      pickup: 'شبرا الخيمة',
      dropoff: 'القاهرة - رمسيس',
      paymentMethod: 'محفظة',
      status: 'reserved',
    ),
    TripPassenger(
      id: 'pax-3',
      name: 'كريم عادل',
      phone: '01000000003',
      seat: 'م7',
      pickup: 'بنها',
      dropoff: 'شبرا الخيمة',
      paymentMethod: 'اشتراك شهري',
      status: 'subscription',
    ),
  ],
  events: const [],
  notes: const [],
);

/// A newly created trip with no driver/vehicle yet — the publish blocker
/// (finding: previously only readable on hover) should render as a visible
/// banner under the header.
final _blockedTrip = OperationTrip(
  id: 'trip-2',
  routeId: 'route-1',
  route: 'بنها - القاهرة',
  routePoints: _routePoints,
  driverId: '',
  driver: 'غير معيّن',
  vehicleId: '',
  vehicle: 'غير معيّنة',
  date: DateTime.now().add(const Duration(days: 2)).toIso8601String(),
  departure: '09:00',
  arrival: '',
  status: OperationTripStatus.scheduled,
  capacity: 0,
  ticketPrice: 60,
  seats: const [],
  passengers: const [],
  events: const [],
  notes: const [],
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

  testWidgets(
    'overview tab, light — sectioned route/vehicle/capacity/financial',
    (tester) async {
      await _captureWorkspace(
        tester,
        'trip_details_1_overview_light',
        trip: _richTrip,
      );
    },
  );

  testWidgets('passengers tab, light — per-row payment-status chip', (
    tester,
  ) async {
    await _captureWorkspace(
      tester,
      'trip_details_2_passengers_light',
      trip: _richTrip,
      tab: TripWorkspaceTab.passengers,
    );
  });

  testWidgets('overview tab, light — publish blocker visible without hover', (
    tester,
  ) async {
    await _captureWorkspace(
      tester,
      'trip_details_3_publish_blocker_light',
      trip: _blockedTrip,
    );
  });

  testWidgets(
    'row card, light — kpiTint badge, bucketed occupancy bar, price',
    (tester) async {
      tester.view.physicalSize = const Size(900, 260);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _themeWithHostFont(dark: false),
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: RepaintBoundary(key: key, child: child!),
          ),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: TripRowCard(trip: _richTrip, onOpenDetails: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await expectLater(
        find.byKey(key),
        matchesGoldenFile('_captures/trip_details_4_row_card_light.png'),
      );
    },
  );
}

Future<void> _captureWorkspace(
  WidgetTester tester,
  String name, {
  required OperationTrip trip,
  TripWorkspaceTab tab = TripWorkspaceTab.overview,
}) async {
  tester.view.physicalSize = const Size(1400, 1100);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final cubit = _cubit()..showDetails(trip);
  if (tab != TripWorkspaceTab.overview) {
    cubit.changeWorkspaceTab(tab);
  }

  final key = GlobalKey();
  await tester.pumpWidget(
    BlocProvider<TripDetailsCubit>.value(
      value: cubit,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _themeWithHostFont(dark: false),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: RepaintBoundary(key: key, child: child!),
        ),
        home: const Scaffold(
          body: SizedBox(
            width: 1180,
            height: 840,
            child: TripDetailsWorkspace(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
  await cubit.close();
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
      dark
          ? AppSurfaceStyle.flat(scheme)
          : AppSurfaceStyle.dashboardLight(scheme),
    ],
  );
}
