import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tracking_trip.dart';
import '../../domain/usecases/confirm_boarding_usecase.dart';
import '../../domain/usecases/get_tracking_trip_usecase.dart';
import '../../domain/usecases/watch_tracking_trip_usecase.dart';
import 'tracking_state.dart';
import 'tracking_subscriptions.dart';

/// Owns the rider's trip *document* and the one action they can take on it.
///
/// The live axis — positions, link health, freshness, route progress and ETAs —
/// belongs to `LiveTrackingBloc`. This cubit is what the trip *is*: which trip,
/// which booking, which captain and vehicle, which seat, and whether the rider
/// has boarded. It fetches that, keeps it current when the operation changes it,
/// and confirms boarding.
///
/// The trip state shown here is always the one the operation is actually in: it
/// is derived in the data layer from the trip's status and the captain's events.
/// There is deliberately no way for the UI to set it.
class TrackingCubit extends Cubit<TrackingState> {
  TrackingCubit({
    required GetTrackingTripUseCase getTrackingTrip,
    required WatchTrackingTripUseCase watchTrackingTrip,
    required ConfirmBoardingUseCase confirmBoarding,
  }) : _getTrackingTrip = getTrackingTrip,
       _confirmBoarding = confirmBoarding,
       super(const TrackingLoading()) {
    _subscriptions = TrackingSubscriptions(
      watchTrackingTrip: watchTrackingTrip,
      onTripChanged: () => _fetch(silent: true),
    );
  }

  final GetTrackingTripUseCase _getTrackingTrip;
  final ConfirmBoardingUseCase _confirmBoarding;
  late final TrackingSubscriptions _subscriptions;

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

      emit(TrackingLoaded(data: data));
      _subscriptions.syncTripChanges(data.tripId!);
    } catch (error) {
      if (isClosed) return;

      if (silent && current is TrackingLoaded) {
        emit(current.copyWith(isRefreshing: false));
        return;
      }
      emit(TrackingError(error.toString()));
    }
  }

  /// A position arrived for a trip the operation still calls "not started".
  ///
  /// The captain's bus is demonstrably moving, so telling the rider it has not
  /// set off would be worse than the record being a few minutes behind. This is
  /// the one place a live fix touches the trip document, and it is driven from
  /// the screen by `LiveTrackingBloc` rather than by a second subscription here.
  void noteVehicleMoving() {
    final current = state;
    if (current is! TrackingLoaded) return;
    if (current.data.tripState != TrackingTripState.notStarted) return;
    emit(
      current.copyWith(
        data: current.data.copyWith(tripState: TrackingTripState.driverOnWay),
      ),
    );
  }

  /// The rider confirming they are aboard.
  ///
  /// On success the refetch picks up a booking that is now `boarded`, which does
  /// three things at once: the station's tally drops a pending rider (the captain
  /// sees it immediately over realtime), the boarding card is replaced by the
  /// confirmation, and the screen re-requests tracking — which the bloc answers
  /// with `unavailable`, dropping this rider's position feed. The failure path
  /// leaves everything exactly as it was and surfaces the server's reason.
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

  @override
  Future<void> close() {
    _subscriptions.cancelAll();
    return super.close();
  }
}
