// Throwaway visual check — not part of the suite.
//
//     flutter test test/apps/dashboard/features/trips/_scratch_trips_screen_capture.dart --update-goldens
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_color_scheme.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_light_colors.dart';
import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/apps/dashboard/features/trips/presentation/screens/trips_screen.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_lifecycle.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_package_offer.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_pricable_package.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_pricing.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/domain/entities/trip_driver_option.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/repositories/trips_repository.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/usecases/trip_management_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trips_list_cubit.dart';

const _captureFont = 'CaptureArabic';

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

final _today = _ymd(DateTime.now());
final _tomorrow = _ymd(DateTime.now().add(const Duration(days: 1)));
final _yesterday = _ymd(DateTime.now().subtract(const Duration(days: 1)));

OperationTrip _trip({
  required String id,
  required String route,
  required OperationTripStatus status,
  required String date,
  required String departure,
  required int capacity,
  required int bookedSeats,
  String driverId = 'd-1',
  String driver = 'محمد علي',
  String vehicle = 'MEG-003',
  double ticketPrice = 75,
}) {
  return OperationTrip(
    id: id,
    routeId: 'r-$id',
    route: route,
    routePoints: const [],
    driverId: driverId,
    driver: driver,
    vehicleId: driverId.isEmpty ? '' : 'v-$id',
    vehicle: driverId.isEmpty ? '' : vehicle,
    vehicleType: 'hiace',
    date: date,
    departure: departure,
    arrival: '',
    status: status,
    capacity: capacity,
    ticketPrice: ticketPrice,
    seats: List.generate(
      capacity,
      (i) => TripSeat(
        id: 's-$id-$i',
        label: '${i + 1}',
        row: i ~/ 4,
        column: i % 4,
        state: i < bookedSeats ? TripSeatState.paid : TripSeatState.available,
      ),
    ),
    passengers: List.generate(
      bookedSeats,
      (i) => TripPassenger(
        id: 'p-$id-$i',
        name: 'راكب',
        phone: '01000000000',
        seat: '${i + 1}',
        pickup: '',
        dropoff: '',
        paymentMethod: '',
        status: 'paid',
      ),
    ),
    events: const [],
    notes: const [],
  );
}

final _trips = [
  _trip(
    id: '1',
    route: 'بنها ← القرية الذكية',
    status: OperationTripStatus.inProgress,
    date: _today,
    departure: '07:30',
    capacity: 14,
    bookedSeats: 12,
  ),
  _trip(
    id: '2',
    route: 'بنها ← مدينة نصر',
    status: OperationTripStatus.scheduled,
    date: _today,
    departure: '08:00',
    capacity: 14,
    bookedSeats: 7,
    driverId: '',
    driver: '',
    ticketPrice: 80,
  ),
  _trip(
    id: '3',
    route: 'بنها ← الشيراتون',
    status: OperationTripStatus.openForBooking,
    date: _today,
    departure: '08:30',
    capacity: 14,
    bookedSeats: 4,
    driver: 'إبراهيم خليل',
    vehicle: 'MEG-002',
    ticketPrice: 85,
  ),
  _trip(
    id: '4',
    route: 'بنها ← المهندسين',
    status: OperationTripStatus.scheduled,
    date: _today,
    departure: '09:00',
    capacity: 14,
    bookedSeats: 10,
    driver: 'كريم نصار',
    vehicle: 'MEG-005',
    ticketPrice: 70,
  ),
  _trip(
    id: '5',
    route: 'القرية الذكية ← بنها',
    status: OperationTripStatus.scheduled,
    date: _today,
    departure: '16:30',
    capacity: 14,
    bookedSeats: 13,
  ),
  _trip(
    id: '6',
    route: 'بنها ← أكتوبر',
    status: OperationTripStatus.inProgress,
    date: _today,
    departure: '07:00',
    capacity: 14,
    bookedSeats: 11,
    driver: 'مصطفى فؤاد',
    vehicle: 'MEG-007',
    ticketPrice: 90,
  ),
  _trip(
    id: '7',
    route: 'بنها ← المعادي',
    status: OperationTripStatus.cancelled,
    date: _today,
    departure: '06:45',
    capacity: 14,
    bookedSeats: 0,
    driver: 'أحمد حسن',
    vehicle: 'MEG-001',
    ticketPrice: 95,
  ),
  _trip(
    id: '8',
    route: 'بنها ← الشيراتون',
    status: OperationTripStatus.completed,
    date: _yesterday,
    departure: '08:30',
    capacity: 14,
    bookedSeats: 14,
    driver: 'هاني رمزي',
    vehicle: 'MEG-004',
    ticketPrice: 85,
  ),
  // Stale: still "open for booking" on a date that has already passed.
  _trip(
    id: '9',
    route: 'بنها ← دمياط',
    status: OperationTripStatus.openForBooking,
    date: _yesterday,
    departure: '07:00',
    capacity: 14,
    bookedSeats: 2,
    driver: 'وائل فتحي',
    vehicle: 'MEG-008',
    ticketPrice: 100,
  ),
  _trip(
    id: '10',
    route: 'بنها ← الزقازيق',
    status: OperationTripStatus.scheduled,
    date: _tomorrow,
    departure: '07:30',
    capacity: 14,
    bookedSeats: 0,
    driverId: '',
    driver: '',
    ticketPrice: 65,
  ),
];

class _FakeRepo implements TripsRepository {
  _FakeRepo(this.trips);

  List<OperationTrip> trips;
  final _changes = StreamController<void>.broadcast();

  @override
  Future<List<OperationTrip>> getTrips() async => trips;

  @override
  Future<void> deleteTrip(String tripId) async {
    trips = trips.where((t) => t.id != tripId).toList();
  }

  @override
  Stream<void> watchTripsChanges() => _changes.stream;

  @override
  Stream<void> watchTripChanges(String tripId) => const Stream.empty();

  @override
  Future<OperationTrip> getTripById(String tripId) =>
      throw UnimplementedError();

  @override
  Future<OperationTrip> updateTripStatus(
    String tripId,
    OperationTripStatus status, {
    String? reason,
  }) => throw UnimplementedError();

  @override
  Future<OperationTrip> cancelTrip(String tripId, String reason) =>
      throw UnimplementedError();

  @override
  Future<OperationTrip> closeStaleTrip(
    String tripId,
    StaleTripOutcome outcome, {
    String? reason,
  }) => throw UnimplementedError();

  @override
  Future<OperationTrip> updateSeatState(
    String tripId,
    String seatId,
    TripSeatState state,
  ) => throw UnimplementedError();

  @override
  Future<OperationTrip> createTrip(CreateTripInput input) =>
      throw UnimplementedError();

  @override
  Future<OperationTrip> updateTripInfo(OperationTrip trip) =>
      throw UnimplementedError();

  @override
  Future<OperationTrip> updatePassenger(
    String tripId,
    TripPassenger passenger,
  ) => throw UnimplementedError();

  @override
  Future<OperationTrip> cancelPassenger(String tripId, String passengerId) =>
      throw UnimplementedError();

  @override
  Future<OperationTrip> movePassenger(
    String tripId,
    String passengerId,
    String seatLabel,
  ) => throw UnimplementedError();

  @override
  Future<List<TripPricing>> getTripPricing(String tripId) =>
      throw UnimplementedError();

  @override
  Future<TripPricing> upsertTripPricing(TripPricing pricing) =>
      throw UnimplementedError();

  @override
  Future<TripPricing> toggleTripPricingStatus(
    String pricingId,
    bool isActive,
  ) => throw UnimplementedError();

  @override
  Future<List<TripEvent>> getTripEvents(String tripId) =>
      throw UnimplementedError();

  @override
  Future<List<TripDriverOption>> getActiveDrivers() =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getActiveRoutes() =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getResourceConflicts({
    required String date,
    required String departureTime,
    required String arrivalTime,
  }) => throw UnimplementedError();

  @override
  Future<List<TripPricablePackage>> getOfficePricablePackages() =>
      throw UnimplementedError();

  @override
  Future<List<TripPricablePackage>> getTripScopedPackages(String tripId) =>
      Future.value(const []);

  @override
  Future<String> createTripPackage({
    required String tripId,
    required TripPackageOffer offer,
  }) => throw UnimplementedError();
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

  testWidgets('scratch: trips screen, light', (tester) async {
    tester.view.physicalSize = const Size(2000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = _FakeRepo(List.of(_trips));
    final cubit = TripsListCubit(
      GetOperationTripsUseCase(repo),
      DeleteTripUseCase(repo),
      WatchOperationTripsUseCase(repo),
    );
    await cubit.load();

    final theme = _themeWithHostFont();

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: RepaintBoundary(key: key, child: child!),
        ),
        home: Scaffold(
          body: BlocProvider<TripsListCubit>.value(
            value: cubit,
            child: BlocBuilder<TripsListCubit, TripsListState>(
              builder: (context, state) => state is TripsListLoaded
                  ? TripsLoadedView(state: state)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('_captures/_scratch_trips_screen.png'),
    );
    await cubit.close();
  });
}

/// [DashboardAppTheme] itself builds its text theme through
/// `GoogleFonts.cairoTextTheme()`, which the test binding's blocked network
/// turns into a hard failure rather than a fallback. This hand-builds the
/// same palette + [AppSurfaceStyle.ewt] card treatment with the host font
/// substituted directly instead of routing through google_fonts at all.
ThemeData _themeWithHostFont() {
  final scheme = dashboardLightColorScheme();
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    fontFamily: _captureFont,
    scaffoldBackgroundColor: DashboardLightColors.background,
    canvasColor: DashboardLightColors.background,
    cardColor: scheme.surface,
    dividerColor: scheme.outline,
    shadowColor: DashboardLightColors.shadow,
    extensions: [AppSurfaceStyle.ewt(scheme)],
  );
}
