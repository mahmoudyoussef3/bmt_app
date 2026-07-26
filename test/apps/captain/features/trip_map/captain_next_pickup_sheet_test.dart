import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/entities/passenger.dart';
import 'package:bmt_app/apps/captain/features/trip_map/domain/entities/pickup_plan.dart';
import 'package:bmt_app/apps/captain/features/trip_map/presentation/cubit/captain_trip_map_state.dart';
import 'package:bmt_app/apps/captain/features/trip_map/presentation/widgets/panel/captain_next_pickup_sheet.dart';

void main() {
  Future<void> pump(WidgetTester tester, CaptainTripMapState state) {
    return tester.pumpWidget(
      MaterialApp(
        theme: CaptainTheme.light(),
        locale: const Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: CaptainNextPickupSheet(
              state: state,
              onConfirm: (_) {},
              onAbsent: (_) {},
              onReset: (_) {},
              onArrived: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the active pickup stop, its rider, and a board action', (
    tester,
  ) async {
    await pump(
      tester,
      _state(
        PickupPlan(
          stops: [
            PickupStop(
              name: 'محطة مصر',
              stopIndex: 0,
              stopId: 's0',
              latitude: 31.2,
              longitude: 29.9,
              riders: const [
                PickupRider(
                  tripPassengerId: 'p1',
                  name: 'أحمد محمد',
                  seat: 'A1',
                  phone: '0100',
                  status: PassengerBoardingStatus.pending,
                ),
              ],
            ),
          ],
          activeIndex: 0,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('المحطة القادمة للتجميع'), findsOneWidget);
    expect(find.text('محطة مصر'), findsOneWidget);
    expect(find.text('أحمد محمد'), findsOneWidget);
    expect(find.text('تأكيد الصعود'), findsOneWidget);
  });

  testWidgets('reads as all-collected once every rider is resolved', (
    tester,
  ) async {
    await pump(
      tester,
      _state(
        PickupPlan(
          stops: [
            PickupStop(
              name: 'محطة مصر',
              stopIndex: 0,
              stopId: 's0',
              riders: const [
                PickupRider(
                  tripPassengerId: 'p1',
                  name: 'أحمد محمد',
                  seat: 'A1',
                  phone: '0100',
                  status: PassengerBoardingStatus.boarded,
                ),
              ],
            ),
          ],
          activeIndex: null,
        ),
        boarded: 1,
        riders: 1,
      ),
    );
    await tester.pump();

    expect(find.text('تم تجميع كل الركاب'), findsOneWidget);
  });

  testWidgets('a finished trip reads as tracking stopped', (tester) async {
    await pump(
      tester,
      _state(const PickupPlan.empty(), phase: CaptainMapPhase.completed),
    );
    await tester.pump();

    expect(find.textContaining('اكتملت الرحلة'), findsOneWidget);
  });
}

CaptainTripMapState _state(
  PickupPlan pickup, {
  CaptainMapPhase phase = CaptainMapPhase.boarding,
  int boarded = 0,
  int riders = 1,
}) {
  return CaptainTripMapState(
    tripId: 'trip-1',
    phase: phase,
    gpsHealth: GpsHealth.live,
    pickup: pickup,
    riderCount: riders,
    boardedCount: boarded,
  );
}
