// Throwaway visual check — not part of the suite.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/theme/app_theme.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/features/trips/presentation/widgets/trips_analytics.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/presentation/cubit/trips_list_cubit.dart';

const _captureFont = 'CaptureArabic';

OperationTrip _trip({
  required String id,
  required String route,
  required OperationTripStatus status,
  required int capacity,
  required int bookedSeats,
}) {
  return OperationTrip(
    id: id,
    routeId: 'r-$id',
    route: route,
    routePoints: const [],
    driverId: 'd-$id',
    driver: 'سائق',
    vehicleId: 'v-$id',
    vehicle: 'مركبة',
    vehicleType: 'hiace',
    date: DateTime.now().toIso8601String(),
    departure: '08:00',
    arrival: '',
    status: status,
    capacity: capacity,
    ticketPrice: 50,
    seats: const [],
    passengers: const [],
    events: const [],
    notes: const [],
    bookedSeats: bookedSeats,
  );
}

final _trips = [
  _trip(id: '1', route: 'marg - new cairo', status: OperationTripStatus.completed, capacity: 14, bookedSeats: 14),
  _trip(id: '2', route: 'marg - new cairo', status: OperationTripStatus.completed, capacity: 14, bookedSeats: 12),
  _trip(id: '3', route: 'marg - new cairo', status: OperationTripStatus.completed, capacity: 14, bookedSeats: 0),
  _trip(id: '4', route: 'test new route', status: OperationTripStatus.openForBooking, capacity: 14, bookedSeats: 6),
  _trip(id: '5', route: 'test new route', status: OperationTripStatus.scheduled, capacity: 14, bookedSeats: 3),
  _trip(id: '6', route: 'Banha - American Uni', status: OperationTripStatus.cancelled, capacity: 14, bookedSeats: 0),
  _trip(id: '7', route: 'American University i', status: OperationTripStatus.boarding, capacity: 14, bookedSeats: 11),
  _trip(id: '8', route: 'Zefta - American Univ', status: OperationTripStatus.inProgress, capacity: 14, bookedSeats: 14),
];

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(_captureFont)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  });

  testWidgets('scratch: trips analytics, light', (tester) async {
    tester.view.physicalSize = const Size(2000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final theme = DashboardAppTheme.light().copyWith(
      textTheme: DashboardAppTheme.light().textTheme.apply(fontFamily: _captureFont),
    );

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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TripsAnalytics(state: TripsListLoaded(trips: _trips)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('_captures/_scratch_trips_analytics.png'),
    );
  });
}
