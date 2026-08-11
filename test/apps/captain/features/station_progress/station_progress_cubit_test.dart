import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_action_failure.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_passenger.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/repositories/station_progress_repository.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/arrive_at_station_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/depart_station_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/get_station_passengers_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/resolve_no_show_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/usecases/watch_station_board_usecase.dart';
import 'package:bmt_app/apps/captain/features/station_progress/presentation/cubit/station_progress_cubit.dart';
import 'package:bmt_app/core/tracking/progress/station_board.dart';

void main() {
  late _FakeRepository repository;
  late StationProgressCubit cubit;

  setUp(() {
    repository = _FakeRepository();
    cubit = StationProgressCubit(
      watchBoard: WatchStationBoardUseCase(repository),
      arriveAtStation: ArriveAtStationUseCase(repository),
      departStation: DepartStationUseCase(repository),
      resolveNoShow: ResolveNoShowUseCase(repository),
      getStationPassengers: GetStationPassengersUseCase(repository),
    );
  });

  tearDown(() => cubit.close());

  test('watching a trip loads the board and clears the loading flag', () async {
    cubit.watch('trip-1');
    repository.emit(StationBoard([_station(1, 'محطة بنها')]));
    await _settle();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.board.stations, hasLength(1));
    expect(repository.watchedTripId, 'trip-1');
  });

  test('watching the same trip twice does not re-subscribe', () async {
    cubit.watch('trip-1');
    await _settle();
    cubit.watch('trip-1');

    expect(repository.watchCount, 1);
  });

  test('a stream error leaves the board on screen rather than blanking it',
      () async {
    cubit.watch('trip-1');
    repository.emit(StationBoard([_station(1, 'محطة بنها')]));
    await _settle();

    repository.emitError(Exception('socket dropped'));
    await _settle();

    expect(cubit.state.board.stations, hasLength(1));
    expect(cubit.state.isLoading, isFalse);
  });

  test('arriving calls the RPC path exactly once', () async {
    cubit.watch('trip-1');
    await _settle();

    await cubit.arriveAtCurrentStation();

    expect(repository.arrivals, ['trip-1']);
    expect(cubit.state.isSubmitting, isFalse);
    expect(cubit.state.failure, isNull);
  });

  test('a refused departure surfaces as the typed refusal, not a raw string',
      () async {
    cubit.watch('trip-1');
    await _settle();
    repository.departureFailure = 'passengers_not_boarded:2';

    await cubit.departCurrentStation();

    final failure = cubit.state.failure;
    expect(failure, isNotNull);
    expect(failure!.failure, StationActionFailure.passengersNotBoarded);
    expect(failure.pendingCount, 2);
    expect(cubit.state.isSubmitting, isFalse);
  });

  test('a second tap while a departure is in flight is dropped — a double tap '
      'must never queue up a departure for the next station too', () async {
    cubit.watch('trip-1');
    await _settle();

    final gate = Completer<void>();
    repository.hold = gate.future;

    final first = cubit.departCurrentStation();
    await _settle();
    final second = cubit.departCurrentStation();
    await _settle();

    gate.complete();
    await Future.wait([first, second]);

    expect(repository.departures, ['trip-1']);
  });

  test('a successful action clears the previous refusal', () async {
    cubit.watch('trip-1');
    await _settle();

    repository.departureFailure = 'departure_time_not_reached:08:45';
    await cubit.departCurrentStation();
    expect(cubit.state.failure, isNotNull);

    repository.departureFailure = null;
    await cubit.departCurrentStation();

    expect(cubit.state.failure, isNull);
  });

  test('a refusal can be dismissed by the captain', () async {
    cubit.watch('trip-1');
    await _settle();
    repository.departureFailure = 'no_current_station';
    await cubit.departCurrentStation();

    cubit.dismissFailure();

    expect(cubit.state.failure, isNull);
  });

  test('a no-show is forwarded with its reason and note', () async {
    cubit.watch('trip-1');
    await _settle();

    await cubit.resolveNoShow(
      passengerId: 'pax-1',
      reason: NoShowReason.other,
      note: 'اتصل وقال إنه لن يحضر',
    );

    expect(repository.noShows, [
      ('pax-1', 'other', 'اتصل وقال إنه لن يحضر'),
    ]);
  });

  test('the pending list for a station is looked up by route point id', () async {
    cubit.watch('trip-1');
    await _settle();
    repository.passengers = [
      const StationPassenger(
        id: 'pax-1',
        name: 'راكب',
        seatLabel: 'A1',
        phone: '0100',
        status: StationPassengerStatus.pending,
      ),
    ];

    final result = await cubit.passengersAt(
      _station(1, 'محطة بنها', routePointId: 'rp-1'),
    );

    expect(result, hasLength(1));
    expect(repository.passengerLookup, ('trip-1', 'rp-1', 'محطة بنها'));
  });

  test('a failed passenger lookup degrades to an empty list rather than '
      'taking the sheet down', () async {
    cubit.watch('trip-1');
    await _settle();
    repository.passengerLookupFails = true;

    expect(await cubit.passengersAt(_station(1, 'محطة بنها')), isEmpty);
  });

  test('actions before a trip is watched are no-ops', () async {
    await cubit.departCurrentStation();

    expect(repository.departures, isEmpty);
  });
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

TripStation _station(int sequence, String name, {String? routePointId}) {
  return TripStation(
    id: 'st-$sequence',
    name: name,
    sequence: sequence,
    status: TripStationStatus.upcoming,
    routePointId: routePointId,
  );
}

class _FakeRepository implements StationProgressRepository {
  final _controller = StationBoardController();
  final arrivals = <String>[];
  final departures = <String>[];
  final noShows = <(String, String, String?)>[];

  String? watchedTripId;
  int watchCount = 0;
  String? departureFailure;
  Future<void>? hold;
  List<StationPassenger> passengers = const [];
  (String, String?, String)? passengerLookup;
  bool passengerLookupFails = false;

  void emit(StationBoard board) => _controller.add(board);
  void emitError(Object error) => _controller.addError(error);

  @override
  Stream<StationBoard> watchBoard(String tripId) {
    watchedTripId = tripId;
    watchCount++;
    return _controller.stream;
  }

  @override
  Future<void> arriveAtStation(String tripId) async => arrivals.add(tripId);

  @override
  Future<void> departStation(String tripId) async {
    if (hold != null) await hold;
    if (departureFailure case final code?) {
      throw stationFailureFrom(code);
    }
    departures.add(tripId);
  }

  @override
  Future<void> resolveNoShow({
    required String passengerId,
    required NoShowReason reason,
    String? note,
  }) async => noShows.add((passengerId, reason.wireValue, note));

  @override
  Future<List<StationPassenger>> passengersAt({
    required String tripId,
    String? routePointId,
    required String pointName,
  }) async {
    if (passengerLookupFails) throw Exception('read failed');
    passengerLookup = (tripId, routePointId, pointName);
    return passengers;
  }
}

class StationBoardController {
  final _controller = StreamController<StationBoard>.broadcast();

  Stream<StationBoard> get stream => _controller.stream;
  void add(StationBoard board) => _controller.add(board);
  void addError(Object error) => _controller.addError(error);
}
