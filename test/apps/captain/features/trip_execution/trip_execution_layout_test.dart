import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/captain/core/trips/captain_trip_stage.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/entities/trip_execution_state.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/cubit/trip_execution_state.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/widgets/trip_execution_action_bar.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/widgets/trip_execution_canopy.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/widgets/trip_execution_tools.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_passenger.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/repositories/station_progress_repository.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/arrive_at_station_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/depart_station_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/get_station_passengers_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/resolve_no_show_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/watch_station_board_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/presentation/cubit/station_progress_cubit.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';

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

  // A captain running the system font large is the case the fixed-height
  // docked bar is most likely to break on, so every size is swept at the
  // default scale and at an enlarged one.
  const scales = <double>[1.0, 1.3, 1.6];

  for (final size in sizes.entries) {
    for (final scale in scales) {
      for (final status in TripExecutionStatus.values) {
        testWidgets(
          'canopy and docked bar hold at ${size.key} @ $scale — ${status.name}',
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
                scale: scale,
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
  }

  for (final scale in scales) {
    testWidgets(
      'the docked bar keeps one height across every stage @ textScale $scale, '
      'so the page above never reflows on a transition',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final trip = _trip();
        final heights = <TripExecutionStatus, double>{};

        for (final status in TripExecutionStatus.values) {
          final snapshot = _snapshot(status);
          await tester.pumpWidget(
            _host(
              scale: scale,
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
          expect(tester.takeException(), isNull);
          heights[status] = tester
              .getSize(find.byType(TripExecutionActionBar))
              .height;
        }

        // Committing an action swaps the bar for a spinner. If that disagrees
        // with the resting height, the page jumps at the moment of the tap —
        // the one moment the captain is looking at their thumb.
        await tester.pumpWidget(
          _host(
            scale: scale,
            body: const SizedBox.shrink(),
            bottomBar: TripExecutionActionBar(
              stage: CaptainTripStage.boarding,
              state: TripExecutionLoading(
                _snapshot(TripExecutionStatus.boarding),
              ),
              tripId: trip.id,
              departureTime: trip.departureTime,
            ),
          ),
        );
        // Not `pumpAndSettle`: the spinner animates forever and would never
        // settle.
        await tester.pump();
        expect(tester.takeException(), isNull);
        final busyHeight = tester
            .getSize(find.byType(TripExecutionActionBar))
            .height;

        expect(
          {...heights.values, busyHeight},
          hasLength(1),
          reason:
              'action bar heights differ per stage: $heights, busy: $busyHeight',
        );
      },
    );
  }

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

/// Once the trip is live the docked bar renders the *station* action, so the
/// host has to carry a [StationProgressCubit]. [board] is what that cubit
/// reports; the default empty board is the "trip has no stations" fallback.
Widget _host({
  required Widget body,
  required Widget bottomBar,
  double scale = 1.0,
  StationBoard board = const StationBoard.empty(),
}) {
  return MaterialApp(
    theme: CaptainTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider<StationProgressCubit>(
          create: (_) => _stationCubit(board),
          child: Scaffold(body: body, bottomNavigationBar: bottomBar),
        ),
      ),
    ),
  );
}

StationProgressCubit _stationCubit(StationBoard board) {
  final repository = _StubStationRepository(board);
  return StationProgressCubit(
    watchBoard: WatchStationBoardUseCase(repository),
    arriveAtStation: ArriveAtStationUseCase(repository),
    departStation: DepartStationUseCase(repository),
    resolveNoShow: ResolveNoShowUseCase(repository),
    getStationPassengers: GetStationPassengersUseCase(repository),
  )..watch('trip-1');
}

class _StubStationRepository implements StationProgressRepository {
  const _StubStationRepository(this.board);

  final StationBoard board;

  @override
  Stream<StationBoard> watchBoard(String tripId) => Stream.value(board);

  @override
  Future<void> arriveAtStation(String tripId) async {}

  @override
  Future<void> departStation(String tripId) async {}

  @override
  Future<void> resolveNoShow({
    required String passengerId,
    required NoShowReason reason,
    String? note,
  }) async {}

  @override
  Future<List<StationPassenger>> passengersAt({
    required String tripId,
    String? routePointId,
    required String pointName,
  }) async => const [];
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
