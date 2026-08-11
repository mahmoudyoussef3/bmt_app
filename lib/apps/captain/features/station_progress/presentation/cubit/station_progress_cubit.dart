import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/tracking/progress/station_board.dart';

import '../../domain/entities/station_action_failure.dart';
import '../../domain/entities/station_passenger.dart';
import '../../domain/usecases/arrive_at_station_usecase.dart';
import '../../domain/usecases/depart_station_usecase.dart';
import '../../domain/usecases/get_station_passengers_usecase.dart';
import '../../domain/usecases/resolve_no_show_usecase.dart';
import '../../domain/usecases/watch_station_board_usecase.dart';
import 'station_progress_state.dart';

/// Drives the captain's station flow.
///
/// It holds no rule of its own. Whether the vehicle may leave is decided by
/// `captain_depart_station`; this cubit asks, and turns the refusal into
/// something the screen can say. The gate rendered on the button comes from
/// [StationBoard.gateAt], which evaluates the same two conditions locally so the
/// captain is not made to tap a button that is going to be refused — but the
/// refusal is still what settles it.
class StationProgressCubit extends Cubit<StationProgressState> {
  StationProgressCubit({
    required WatchStationBoardUseCase watchBoard,
    required ArriveAtStationUseCase arriveAtStation,
    required DepartStationUseCase departStation,
    required ResolveNoShowUseCase resolveNoShow,
    required GetStationPassengersUseCase getStationPassengers,
  }) : _watchBoard = watchBoard,
       _arriveAtStation = arriveAtStation,
       _departStation = departStation,
       _resolveNoShow = resolveNoShow,
       _getStationPassengers = getStationPassengers,
       super(const StationProgressState());

  final WatchStationBoardUseCase _watchBoard;
  final ArriveAtStationUseCase _arriveAtStation;
  final DepartStationUseCase _departStation;
  final ResolveNoShowUseCase _resolveNoShow;
  final GetStationPassengersUseCase _getStationPassengers;

  StreamSubscription<StationBoard>? _subscription;
  String? _tripId;

  void watch(String tripId) {
    if (_tripId == tripId && _subscription != null) return;
    _tripId = tripId;
    _subscription?.cancel();
    emit(const StationProgressState());
    _subscription = _watchBoard(tripId).listen(
      (board) {
        if (isClosed) return;
        emit(state.copyWith(board: board, isLoading: false));
      },
      // A dropped socket must not blank the board the captain is working from.
      // The next event — or the next action's refresh — repairs it.
      onError: (_) {
        if (isClosed) return;
        emit(state.copyWith(isLoading: false));
      },
    );
  }

  Future<void> arriveAtCurrentStation() =>
      _run((tripId) => _arriveAtStation(tripId));

  Future<void> departCurrentStation() =>
      _run((tripId) => _departStation(tripId));

  /// Records why a rider is not travelling. Once accepted, the station's boarding
  /// requirement can be satisfied — which is the only way past a passenger who
  /// never arrived.
  Future<void> resolveNoShow({
    required String passengerId,
    required NoShowReason reason,
    String? note,
  }) => _run(
    (_) => _resolveNoShow(passengerId: passengerId, reason: reason, note: note),
  );

  Future<List<StationPassenger>> passengersAt(TripStation station) async {
    final tripId = _tripId;
    if (tripId == null) return const [];
    try {
      return await _getStationPassengers(
        tripId: tripId,
        routePointId: station.routePointId,
        pointName: station.name,
      );
    } catch (_) {
      return const [];
    }
  }

  void dismissFailure() {
    if (state.failure == null) return;
    emit(state.copyWith(clearFailure: true));
  }

  /// One in-flight action at a time. A second tap while the first is still
  /// running is dropped rather than queued: the database is idempotent about it,
  /// but a captain double-tapping "متابعة" should not be able to queue up a
  /// departure for the *next* station too.
  Future<void> _run(Future<void> Function(String tripId) action) async {
    final tripId = _tripId;
    if (tripId == null || state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true, clearFailure: true));
    try {
      await action(tripId);
      if (isClosed) return;
      emit(state.copyWith(isSubmitting: false));
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isSubmitting: false,
          failure: error is StationActionException
              ? error
              : stationFailureFrom(error),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
