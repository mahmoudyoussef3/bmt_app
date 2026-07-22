import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/entities/trip_execution_state.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/cubit/trip_execution_state.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/widgets/trip_execution_action_bar.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/widgets/trip_execution_canopy.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/widgets/trip_execution_tools.dart';

/// The execution screen is a stage-coloured canopy over a scrolling body, with
/// the trip's one action docked at the bottom. Both ends are pure layout that
/// changes shape per stage, so pumping them at real phone sizes is what
/// actually proves they hold — the analyzer cannot see a RenderFlex overflow.
///
/// The docked bar matters most: it renders a live button, a two-line waiting
/// panel or a terminal label depending on the stage, and if those disagree on
/// height the page above reflows under the captain's thumb every time a trip
/// transitions.
///
/// Note these assertions are deliberately conservative: `flutter_test` swaps in
/// a test font whose glyphs are far wider than Cairo's, so Arabic strings
/// measure much longer here than on a device.
void main() {
  const sizes = <String, Size>{
    'small': Size(320, 568),
    'medium': Size(390, 844),
    'large': Size(430, 932),
  };

  for (final size in sizes.entries) {
    for (final status in TripExecutionStatus.values) {
      testWidgets(
        'canopy and docked bar hold at ${size.key} — ${status.name}',
        (tester) async {
          tester.view.physicalSize = size.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final trip = _trip();
          final snapshot = _snapshot(status);
          final stage = status.stageAt(
            departureTime: trip.departureTime,
            now: DateTime.now(),
          );

          await tester.pumpWidget(
            _host(
              body: CustomScrollView(
                slivers: [
                  TripExecutionCanopy(
                    trip: trip,
                    snapshot: snapshot,
                    stage: stage,
                  ),
                  SliverToBoxAdapter(
                    child: TripExecutionTools(tripId: trip.id, stage: stage),
                  ),
                ],
              ),
              bottomBar: TripExecutionActionBar(
                stage: stage,
                state: TripExecutionIdle(snapshot),
                tripId: trip.id,
                departureTime: trip.departureTime,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          // The route is the screen's subject and must always be legible.
          expect(find.text('محطة مصر - سيدي جابر'), findsOneWidget);
        },
      );
    }
  }

  testWidgets('the docked bar keeps one height across every stage, so the '
      'page above never reflows on a transition', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final trip = _trip();
    final heights = <TripExecutionStatus, double>{};

    for (final status in TripExecutionStatus.values) {
      final snapshot = _snapshot(status);
      await tester.pumpWidget(
        _host(
          body: const SizedBox.shrink(),
          bottomBar: TripExecutionActionBar(
            stage: status.stageAt(
              departureTime: trip.departureTime,
              now: DateTime.now(),
            ),
            state: TripExecutionIdle(snapshot),
            tripId: trip.id,
            departureTime: trip.departureTime,
          ),
        ),
      );
      await tester.pumpAndSettle();
      heights[status] = tester
          .getSize(find.byType(TripExecutionActionBar))
          .height;
    }

    expect(
      heights.values.toSet(),
      hasLength(1),
      reason: 'action bar heights differ per stage: $heights',
    );
  });

  testWidgets('an emergency call is reachable without scrolling while the '
      'trip is underway, and absent before it starts', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Future<void> pumpAt(CaptainTripStage stage, TripExecutionStatus status) {
      return tester.pumpWidget(
        _host(
          body: const SizedBox.shrink(),
          bottomBar: TripExecutionActionBar(
            stage: stage,
            state: TripExecutionIdle(_snapshot(status)),
            tripId: 'trip-1',
            departureTime: _trip().departureTime,
          ),
        ),
      );
    }

    await pumpAt(CaptainTripStage.underway, TripExecutionStatus.inProgress);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.sos_rounded), findsOneWidget);

    await pumpAt(
      CaptainTripStage.awaitingRelease,
      TripExecutionStatus.scheduled,
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.sos_rounded), findsNothing);
  });
}

Widget _host({required Widget body, required Widget bottomBar}) {
  return MaterialApp(
    theme: CaptainTheme.light(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: body, bottomNavigationBar: bottomBar),
    ),
  );
}

AssignedTrip _trip() {
  final departure = DateTime(2026, 7, 14, 8);
  return AssignedTrip(
    id: 'trip-1',
    route: 'محطة مصر - سيدي جابر',
    vehicleNumber: 'BUS-104',
    plateNumber: 'ط ن ج 4821',
    departureTime: departure,
    expectedArrivalTime: departure.add(const Duration(hours: 3)),
    stops: const [
      AssignedTripStop(id: 's1', name: 'محطة مصر'),
      AssignedTripStop(id: 's2', name: 'سيدي جابر'),
    ],
    passengerCount: 20,
    boardedCount: 12,
  );
}

TripExecutionSnapshot _snapshot(TripExecutionStatus status) {
  return TripExecutionSnapshot(
    status: status,
    passengerCount: 20,
    boardedCount: 12,
    arrivedStationsCount: 1,
  );
}
