import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_action.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_passenger.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/repositories/station_progress_repository.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/arrive_at_station_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/depart_station_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/get_station_passengers_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/resolve_no_show_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/watch_station_board_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/presentation/cubit/station_progress_cubit.dart';
import 'package:bmt_app/apps/captain/features/station_progress/presentation/cubit/station_progress_state.dart';
import 'package:bmt_app/apps/captain/features/station_progress/presentation/widgets/station_primary_action.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';

/// §20: the captain must be able to answer "can I leave now?" from the control
/// itself. These tests assert the three things that makes true — the button is
/// disabled when the rule says no, it *says why*, and tapping it does nothing.
void main() {
  final now = DateTime(2026, 8, 11, 8, 40);

  testWidgets('waiting on passengers: disabled, and the label is the count',
      (tester) async {
    final repository = _StubRepository();
    final board = StationBoard([
      _station(
        arrived: now.subtract(const Duration(minutes: 20)),
        expectedDeparture: now.subtract(const Duration(minutes: 10)),
        expected: 3,
        boarded: 1,
        pending: 2,
      ),
    ]);

    await _pump(tester, repository: repository, board: board, now: now);

    expect(find.text('متبقي راكبان'), findsOneWidget);
    expect(find.text('متابعة إلى المحطة التالية'), findsNothing);

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(
      repository.departures,
      isEmpty,
      reason: 'a disabled gate must not be tappable at all',
    );
  });

  testWidgets('waiting on the clock: disabled, and the label is the time',
      (tester) async {
    final repository = _StubRepository();
    final board = StationBoard([
      _station(
        arrived: now,
        expectedDeparture: DateTime(2026, 8, 11, 8, 45),
        expected: 2,
        boarded: 2,
      ),
    ]);

    await _pump(tester, repository: repository, board: board, now: now);

    expect(find.textContaining('يمكنك المغادرة بعد 08:45'), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    await tester.pump();
    expect(repository.departures, isEmpty);
  });

  testWidgets('both conditions met: enabled, and tapping departs',
      (tester) async {
    final repository = _StubRepository();
    final board = StationBoard([
      _station(
        arrived: now.subtract(const Duration(minutes: 20)),
        expectedDeparture: now.subtract(const Duration(minutes: 10)),
        expected: 2,
        boarded: 2,
      ),
      _station(sequence: 2, name: 'محطة كفر شكر'),
    ]);

    await _pump(tester, repository: repository, board: board, now: now);

    expect(find.text('متابعة إلى المحطة التالية'), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(repository.departures, ['trip-1']);
  });

  testWidgets('driving towards a station offers the arrival report',
      (tester) async {
    final repository = _StubRepository();

    await _pump(
      tester,
      repository: repository,
      board: StationBoard([_station()]),
      now: now,
    );

    expect(find.text('تسجيل الوصول للمحطة'), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(repository.arrivals, ['trip-1']);
  });

  testWidgets('the last station reads as the last one', (tester) async {
    final board = StationBoard([
      _station(
        arrived: now.subtract(const Duration(minutes: 20)),
        expectedDeparture: now.subtract(const Duration(minutes: 10)),
      ),
    ]);

    await _pump(tester, repository: _StubRepository(), board: board, now: now);

    expect(find.text('متابعة — آخر محطة'), findsOneWidget);
  });

  testWidgets('an action in flight shows a spinner and no button',
      (tester) async {
    await _pump(
      tester,
      repository: _StubRepository(),
      board: StationBoard([_station()]),
      now: now,
      submitting: true,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('تسجيل الوصول للمحطة'), findsNothing);
  });

  testWidgets('the button keeps one height across every gate state, so the '
      'page never reflows under the captain\'s thumb', (tester) async {
    final heights = <double>{};

    final boards = <StationBoard>[
      StationBoard([_station()]),
      StationBoard([
        _station(arrived: now, expected: 3, boarded: 1, pending: 2),
      ]),
      StationBoard([
        _station(
          arrived: now,
          expectedDeparture: DateTime(2026, 8, 11, 8, 45),
          expected: 2,
          boarded: 2,
        ),
      ]),
      StationBoard([
        _station(
          arrived: now.subtract(const Duration(minutes: 20)),
          expectedDeparture: now.subtract(const Duration(minutes: 10)),
        ),
      ]),
      const StationBoard.empty(),
    ];

    for (final board in boards) {
      await _pump(tester, repository: _StubRepository(), board: board, now: now);
      heights.add(
        tester.getSize(find.byType(StationPrimaryAction)).height,
      );
    }

    expect(heights, hasLength(1), reason: 'heights differed: $heights');
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required _StubRepository repository,
  required StationBoard board,
  required DateTime now,
  bool submitting = false,
}) async {
  final cubit = StationProgressCubit(
    watchBoard: WatchStationBoardUseCase(repository),
    arriveAtStation: ArriveAtStationUseCase(repository),
    departStation: DepartStationUseCase(repository),
    resolveNoShow: ResolveNoShowUseCase(repository),
    getStationPassengers: GetStationPassengersUseCase(repository),
  );
  addTearDown(cubit.close);

  await tester.pumpWidget(
    MaterialApp(
      theme: CaptainTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocProvider.value(
          value: cubit..watch('trip-1'),
          child: Scaffold(
            body: Center(
              child: StationPrimaryAction(
                action: resolveStationAction(board, now),
                state: StationProgressState(
                  board: board,
                  isLoading: false,
                  isSubmitting: submitting,
                ),
                now: now,
                onComplete: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

TripStation _station({
  int sequence = 1,
  String name = 'محطة بنها',
  DateTime? arrived,
  DateTime? expectedDeparture,
  int expected = 0,
  int boarded = 0,
  int pending = 0,
}) {
  return TripStation(
    id: 'st-$sequence',
    name: name,
    sequence: sequence,
    status: arrived != null
        ? TripStationStatus.waitingForPassengers
        : TripStationStatus.arriving,
    expectedDepartureAt: expectedDeparture,
    actualArrivalAt: arrived,
    expectedBoardings: expected,
    boardedCount: boarded,
    pendingCount: pending,
  );
}

class _StubRepository implements StationProgressRepository {
  final arrivals = <String>[];
  final departures = <String>[];

  @override
  Stream<StationBoard> watchBoard(String tripId) =>
      const Stream<StationBoard>.empty();

  @override
  Future<void> arriveAtStation(String tripId) async => arrivals.add(tripId);

  @override
  Future<void> departStation(String tripId) async => departures.add(tripId);

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
