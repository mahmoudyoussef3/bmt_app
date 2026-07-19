import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip.dart';
import '../../domain/usecases/cancel_booking_usecase.dart';
import '../../domain/usecases/get_trip_details_usecase.dart';
import '../../domain/usecases/get_trips_usecase.dart';
import '../../domain/usecases/watch_trips_usecase.dart';
import 'trips_realtime_refresher.dart';
import 'trips_state.dart';

class TripsCubit extends Cubit<TripsState> {
  TripsCubit({
    required GetTripsUseCase getTrips,
    required GetTripDetailsUseCase getTripDetails,
    required WatchTripsUseCase watchTrips,
    required CancelBookingUseCase cancelBooking,
  }) : _getTrips = getTrips,
       _getTripDetails = getTripDetails,
       _cancelBooking = cancelBooking,
       super(const TripsLoading()) {
    _realtime = TripsRealtimeRefresher(
      watch: watchTrips.call,
      onChange: _refreshFromRealtime,
    );
  }

  final GetTripsUseCase _getTrips;
  final GetTripDetailsUseCase _getTripDetails;
  final CancelBookingUseCase _cancelBooking;
  late final TripsRealtimeRefresher _realtime;

  Future<void> loadTrips() => _load(details: false);

  Future<void> loadTripDetails(String? id) => _load(id: id, details: true);

  Future<void> _load({String? id, required bool details}) async {
    emit(const TripsLoading());
    try {
      final trips = await _getTrips();
      final selected = details ? await _select(id, trips) : null;
      if (isClosed) return;
      emit(TripsLoaded(trips: trips, selectedTrip: selected));
      _realtime.start();
    } catch (error) {
      if (!isClosed) emit(TripsError(error.toString()));
    }
  }

  Future<TripData?> _select(String? id, List<TripData> trips) {
    if (id == null || id.isEmpty) return Future.value(trips.firstOrNull);
    return _getTripDetails(id);
  }

  void setFilter(TripFilter filter) {
    final current = state;
    if (current is TripsLoaded) emit(current.copyWith(filter: filter));
  }

  /// Re-reads the open trip after a review is submitted so the "Rate Trip" CTA
  /// disappears without flashing the loading skeleton. Best-effort.
  Future<void> refreshSelectedTrip(String id) async {
    final current = state;
    if (current is! TripsLoaded || id.isEmpty) return;
    try {
      final trip = await _getTripDetails(id);
      if (isClosed || trip == null) return;
      emit(current.copyWith(selectedTrip: trip));
    } catch (_) {
      // Keep the trip on screen; the next refresh will pick the review up.
    }
  }

  /// Cancels an unapproved booking, then reloads so the trip flips to
  /// "Cancelled" and frees its seat without waiting on the realtime refresh.
  Future<void> cancelTrip(TripData trip, String reason) async {
    final current = state;
    if (current is! TripsLoaded || current.cancelInFlight) return;

    emit(current.copyWith(cancelInFlight: true));
    try {
      await _cancelBooking(trip, reason);
      final trips = await _getTrips();
      if (isClosed) return;
      emit(current.withTrips(trips, cancelledReference: trip.reference));
    } catch (error) {
      if (isClosed) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      emit(current.copyWith(cancelFailure: message));
    }
  }

  Future<void> _refreshFromRealtime() async {
    if (isClosed) return;
    try {
      final trips = await _getTrips();
      final current = state;
      if (isClosed || current is! TripsLoaded) return;
      emit(current.withTrips(trips));
    } catch (_) {
      // A realtime refresh is best-effort; keep the last usable state.
    }
  }

  @override
  Future<void> close() {
    _realtime.dispose();
    return super.close();
  }
}
