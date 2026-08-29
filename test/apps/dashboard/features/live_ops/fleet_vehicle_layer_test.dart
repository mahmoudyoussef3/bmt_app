import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/fleet_feed.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/live_ops_snapshot.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/presentation/widgets/fleet_vehicle_layer.dart';

/// The selected marker carries a label pill under the puck, inside a marker box
/// whose size flutter_map fixes at layer-build time. A box that under-measures
/// that pill paints an overflow stripe over the live map, so the box is checked
/// at every text scale a desk may run.
void main() {
  final now = DateTime(2026, 8, 29, 10);
  final fix = LiveFix(
    latitude: 30.0444,
    longitude: 31.2357,
    recordedAt: now.subtract(const Duration(seconds: 5)),
    heading: 90,
    speedKph: 42,
  );
  final trip = LiveTrip(
    id: 't1',
    statusLabel: 'جارية',
    isInProgress: true,
    routeName: 'المنصورة - القاهرة',
    driverName: 'أحمد محمد',
    driverPhone: '01001234567',
    vehicleLabel: 'kimkm8787',
    tripDate: '2026-08-29',
    departureTime: '08:00',
    capacity: 14,
    bookedSeats: 11,
    lastFix: fix,
  );

  for (final scale in <double>[1.0, 1.3, 1.6]) {
    testWidgets('selected marker does not overflow @ ${scale}x', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: MaterialApp(
            theme: DashboardAppTheme.light(),
            home: Scaffold(
              body: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(30.0444, 31.2357),
                  initialZoom: 13,
                ),
                children: [
                  FleetVehicleLayer(
                    trips: [trip],
                    vehicles: {'t1': TrackedVehicle(fix: fix, receivedAt: now)},
                    now: now,
                    selectedTripId: 't1',
                    onSelect: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('kimkm8787'), findsOneWidget);
    });
  }
}
