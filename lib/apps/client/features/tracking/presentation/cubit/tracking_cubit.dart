import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tracking_trip.dart';
import '../../domain/usecases/confirm_boarding_usecase.dart';
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
    required ConfirmBoardingUseCase confirmBoarding,
  }) : _getTrackingTrip = getTrackingTrip,
       _confirmBoarding = confirmBoarding,
       super(const TrackingLoading()) {
    _subscriptions = TrackingSubscriptions(
      watchVehiclePosition: watchVehiclePosition,
      watchTrackingTrip: watchTrackingTrip,
      onFix: _onFix,
      onTripChanged: () => _fetch(silent: true),
    );
  }

  final GetTrackingTripUseCase _getTrackingTrip;
  final ConfirmBoardingUseCase _confirmBoarding;
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
        ..syncLocation(
          data.tripId!,
          data.tripState,
          canTrack: data.rider.canTrackVehicle,
        )
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

  /// The rider confirming they are aboard.
  ///
  /// On success the refetch picks up a booking that is now `boarded`, which does
  /// three things at once: the station's tally drops a pending rider (the captain
  /// sees it immediately over realtime), the boarding card is replaced by the
  /// confirmation, and [TrackingSubscriptions.syncLocation] drops this rider's
  /// position feed. The failure path leaves everything exactly as it was and
  /// surfaces the server's reason.
  Future<void> confirmBoarding() async {
    final current = state;
    if (current is! TrackingLoaded) return;

    final bookingId = current.data.bookingId;
    if (bookingId == null || current.isBoarding) return;

    emit(current.copyWith(isBoarding: true, clearBoardingError: true));
    try {
      await _confirmBoarding(bookingId);
      if (isClosed) return;
      await _fetch(silent: true);
      if (isClosed) return;
      final refreshed = state;
      if (refreshed is TrackingLoaded) {
        emit(refreshed.copyWith(isBoarding: false));
      }
    } catch (error) {
      if (isClosed) return;
      final latest = state;
      if (latest is! TrackingLoaded) return;
      emit(
        latest.copyWith(
          isBoarding: false,
          boardingError: error.toString().replaceFirst(
            RegExp(r'^Exception: ?'),
            '',
          ),
        ),
      );
    }
  }

  void dismissBoardingError() {
    final current = state;
    if (current is TrackingLoaded && current.boardingError != null) {
      emit(current.copyWith(clearBoardingError: true));
    }
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
