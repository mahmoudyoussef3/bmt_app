import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tracking_trip.dart';
import '../../domain/usecases/get_tracking_trip_usecase.dart';
import '../../domain/usecases/watch_tracking_trip_usecase.dart';
import '../../domain/usecases/watch_vehicle_position_usecase.dart';
import 'tracking_progress_controller.dart';
import 'tracking_state.dart';
import 'tracking_subscriptions.dart';

/// Drives the live tracking screen.
///
/// The trip state shown here is always the one the operation is actually in: it
/// is derived in the data layer from the trip's status and the captain's
/// events. There is deliberately no way for the UI to set it.
class TrackingCubit extends Cubit<TrackingState> {
  TrackingCubit({
    required GetTrackingTripUseCase getTrackingTrip,
    required WatchVehiclePositionUseCase watchVehiclePosition,
    required WatchTrackingTripUseCase watchTrackingTrip,
  }) : _getTrackingTrip = getTrackingTrip,
       super(const TrackingLoading()) {
    _subscriptions = TrackingSubscriptions(
      watchVehiclePosition: watchVehiclePosition,
      watchTrackingTrip: watchTrackingTrip,
      onFix: _onFix,
      onTripChanged: () => _fetch(silent: true),
    );
  }

  final GetTrackingTripUseCase _getTrackingTrip;
  final _progress = TrackingProgressController();
  late final TrackingSubscriptions _subscriptions;

  Timer? _etaTicker;
  String? _bookingId;
  String? _tripId;

  Future<void> load({String? bookingId, String? tripId}) async {
    _bookingId = bookingId;
    _tripId = tripId;
    _subscriptions.cancelAll();
    emit(const TrackingLoading());
    await _fetch(silent: false);
  }

  Future<void> refresh() => _fetch(silent: state is TrackingLoaded);

  Future<void> _fetch({required bool silent}) async {
    final current = state;
    if (silent && current is TrackingLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }

    try {
      final data = await _getTrackingTrip(
        bookingId: _bookingId,
        tripId: _tripId,
      );
      if (isClosed) return;

      if (data.isEmpty) {
        _subscriptions.cancelAll();
        emit(const TrackingEmpty());
        return;
      }

      emit(
        TrackingLoaded(
          data: data,
          progress: _progress.sync(data, now: DateTime.now()),
        ),
      );
      _subscriptions
        ..syncLocation(data.tripId!, data.tripState)
        ..syncTripChanges(data.tripId!);
      _startEtaTicker();
    } catch (error) {
      if (isClosed) return;
      
      if (silent && current is TrackingLoaded) {
        emit(current.copyWith(isRefreshing: false));
        return;
      }
      emit(TrackingError(error.toString()));
    }
  }

  void _onFix(TrackingPoint fix) {
    final current = state;
    if (current is! TrackingLoaded) return;

    final next = current.tripState == TrackingTripState.notStarted
        ? TrackingTripState.driverOnWay
        : current.tripState;

    emit(
      current.copyWith(
        data: current.data.copyWith(tripState: next, vehicleFix: fix),
        progress: _progress.addFix(fix, next, now: DateTime.now()),
      ),
    );
  }

  /// ETAs are moments in time, so they go stale on their own. This re-reads the
  /// engine; it does not touch the network.
  void _startEtaTicker() {
    _etaTicker?.cancel();
    _etaTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      final current = state;
      if (current is! TrackingLoaded || current.tripState.isFinished) return;
      emit(current.copyWith(progress: _progress.tick(DateTime.now())));
    });
  }

  @override
  Future<void> close() {
    _etaTicker?.cancel();
    _subscriptions.cancelAll();
    return super.close();
  }
}
