import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/operation_trip.dart';
import '../../domain/entities/trip_pricing.dart';
import '../../domain/usecases/get_operation_trips_usecase.dart';
import '../../domain/usecases/trip_pricing_usecases.dart';
import '../../domain/usecases/trip_operations_usecases.dart';
import '../../domain/usecases/update_trip_seat_state_usecase.dart';
import '../../domain/usecases/update_trip_status_usecase.dart';
import 'trips_state.dart';

class TripsCubit extends Cubit<TripsState> {
  final GetOperationTripsUseCase _getTrips;
  final UpdateTripStatusUseCase _updateTripStatus;
  final UpdateTripSeatStateUseCase _updateSeatState;
  final CreateOperationTripUseCase _createTrip;
  final UpdateTripInfoUseCase _updateTripInfo;
  final UpdateTripPassengerUseCase _updatePassenger;
  final CancelTripPassengerUseCase _cancelPassenger;
  final MoveTripPassengerUseCase _movePassenger;
  final GetTripPricingUseCase _getTripPricing;
  final SaveTripSegmentPricingUseCase _saveTripPricing;
  final ToggleTripSegmentPricingUseCase _toggleTripPricing;

  TripsCubit({
    required GetOperationTripsUseCase getTrips,
    required UpdateTripStatusUseCase updateTripStatus,
    required UpdateTripSeatStateUseCase updateSeatState,
    required CreateOperationTripUseCase createTrip,
    required UpdateTripInfoUseCase updateTripInfo,
    required UpdateTripPassengerUseCase updatePassenger,
    required CancelTripPassengerUseCase cancelPassenger,
    required MoveTripPassengerUseCase movePassenger,
    required GetTripPricingUseCase getTripPricing,
    required SaveTripSegmentPricingUseCase saveTripPricing,
    required ToggleTripSegmentPricingUseCase toggleTripPricing,
  }) : _getTrips = getTrips,
       _updateTripStatus = updateTripStatus,
       _updateSeatState = updateSeatState,
       _createTrip = createTrip,
       _updateTripInfo = updateTripInfo,
       _updatePassenger = updatePassenger,
       _cancelPassenger = cancelPassenger,
       _movePassenger = movePassenger,
       _getTripPricing = getTripPricing,
       _saveTripPricing = saveTripPricing,
       _toggleTripPricing = toggleTripPricing,
       super(const TripsLoading());

  Future<void> load() async {
    emit(const TripsLoading());
    try {
      final trips = await _getTrips();
      emit(TripsLoaded(trips: trips));
    } catch (error) {
      emit(TripsError(error.toString()));
    }
  }

  Future<void> showDetails(OperationTrip trip) async {
    final current = state;
    if (current is! TripsLoaded) return;
    emit(
      current.copyWith(
        selectedTrip: trip,
        selectedTripPricing: const [],
        pricingLoading: true,
        clearPricingError: true,
      ),
    );
    await loadTripPricing(trip.id);
  }

  void changeWorkspaceTab(TripWorkspaceTab tab) {
    final current = state;
    if (current is! TripsLoaded) return;
    emit(current.copyWith(tab: tab));
  }

  void search(String query) {
    final current = state;
    if (current is! TripsLoaded) return;
    emit(current.copyWith(searchQuery: query));
  }

  void filterStatus(OperationTripStatus? status) {
    final current = state;
    if (current is! TripsLoaded) return;
    emit(
      current.copyWith(statusFilter: status, clearStatusFilter: status == null),
    );
  }

  void filterRoute(String route) {
    final current = state;
    if (current is! TripsLoaded) return;
    emit(current.copyWith(routeFilter: route));
  }

  void filterDriver(String driver) {
    final current = state;
    if (current is! TripsLoaded) return;
    emit(current.copyWith(driverFilter: driver));
  }

  void filterDate(String date) {
    final current = state;
    if (current is! TripsLoaded) return;
    emit(current.copyWith(dateFilter: date));
  }

  void closeDetails() {
    final current = state;
    if (current is! TripsLoaded) return;
    emit(
      current.copyWith(
        clearSelectedTrip: true,
        selectedTripPricing: const [],
        pricingLoading: false,
        clearPricingError: true,
      ),
    );
  }

  Future<void> loadTripPricing(String tripId) async {
    final current = state;
    if (current is! TripsLoaded) return;
    emit(current.copyWith(pricingLoading: true, clearPricingError: true));
    try {
      final pricing = await _getTripPricing(tripId);
      final latest = state;
      if (latest is! TripsLoaded) return;
      emit(
        latest.copyWith(
          selectedTripPricing: pricing,
          pricingLoading: false,
          clearPricingError: true,
        ),
      );
    } catch (error) {
      final latest = state;
      if (latest is! TripsLoaded) return;
      emit(
        latest.copyWith(pricingLoading: false, pricingError: error.toString()),
      );
    }
  }

  Future<String?> saveTripPricing(TripPricing pricing) async {
    final current = state;
    if (current is! TripsLoaded) return null;
    try {
      final saved = await _saveTripPricing(pricing);
      final latest = state;
      if (latest is! TripsLoaded) return null;
      final pricingList =
          [
            saved,
            ...latest.selectedTripPricing.where((item) => item.id != saved.id),
          ]..sort((a, b) {
            final fromOrder = a.fromPointOrder.compareTo(b.fromPointOrder);
            if (fromOrder != 0) return fromOrder;
            return a.toPointOrder.compareTo(b.toPointOrder);
          });
      emit(
        latest.copyWith(
          selectedTripPricing: pricingList,
          pricingLoading: false,
          clearPricingError: true,
        ),
      );
      return null;
    } catch (error) {
      final latest = state;
      if (latest is TripsLoaded) {
        emit(latest.copyWith(pricingError: error.toString()));
      }
      return error.toString();
    }
  }

  Future<void> toggleTripPricing(TripPricing pricing) async {
    final current = state;
    if (current is! TripsLoaded) return;
    try {
      final updated = await _toggleTripPricing(pricing.id, !pricing.isActive);
      final latest = state;
      if (latest is! TripsLoaded) return;
      emit(
        latest.copyWith(
          selectedTripPricing: latest.selectedTripPricing
              .map((item) => item.id == updated.id ? updated : item)
              .toList(),
          clearPricingError: true,
        ),
      );
    } catch (error) {
      final latest = state;
      if (latest is TripsLoaded) {
        emit(latest.copyWith(pricingError: error.toString()));
      }
    }
  }

  Future<void> moveTrip(OperationTrip trip, OperationTripStatus status) async {
    final current = state;
    if (current is! TripsLoaded) return;
    try {
      final updated = await _updateTripStatus(trip.id, status);
      final trips = current.trips
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      emit(
        current.copyWith(
          trips: trips,
          selectedTrip: current.selectedTrip?.id == updated.id
              ? updated
              : current.selectedTrip,
        ),
      );
    } catch (error) {
      emit(TripsError(error.toString()));
    }
  }

  Future<void> createTrip(CreateTripInput input) async {
    final current = state;
    if (current is! TripsLoaded) return;
    try {
      final created = await _createTrip(input);
      emit(
        current.copyWith(
          trips: [created, ...current.trips],
          selectedTrip: created,
        ),
      );
    } catch (error) {
      emit(TripsError(error.toString()));
    }
  }

  Future<void> updateTripInfo(OperationTrip trip) async {
    final current = state;
    if (current is! TripsLoaded) return;
    try {
      final updated = await _updateTripInfo(trip);
      _emitUpdatedTrip(current, updated);
    } catch (error) {
      emit(TripsError(error.toString()));
    }
  }

  Future<void> updateSeatState(
    OperationTrip trip,
    TripSeat seat,
    TripSeatState seatState,
  ) async {
    final current = state;
    if (current is! TripsLoaded) return;
    try {
      final updated = await _updateSeatState(trip.id, seat.id, seatState);
      _emitUpdatedTrip(current, updated);
    } catch (error) {
      emit(TripsError(error.toString()));
    }
  }

  Future<void> updatePassenger(
    OperationTrip trip,
    TripPassenger passenger,
  ) async {
    final current = state;
    if (current is! TripsLoaded) return;
    try {
      final updated = await _updatePassenger(trip.id, passenger);
      _emitUpdatedTrip(current, updated);
    } catch (error) {
      emit(TripsError(error.toString()));
    }
  }

  Future<void> cancelPassenger(
    OperationTrip trip,
    TripPassenger passenger,
  ) async {
    final current = state;
    if (current is! TripsLoaded) return;
    try {
      final updated = await _cancelPassenger(trip.id, passenger.id);
      _emitUpdatedTrip(current, updated);
    } catch (error) {
      emit(TripsError(error.toString()));
    }
  }

  Future<String?> movePassenger(
    OperationTrip trip,
    TripPassenger passenger,
    String seatLabel,
  ) async {
    final current = state;
    if (current is! TripsLoaded) return null;
    try {
      final updated = await _movePassenger(trip.id, passenger.id, seatLabel);
      _emitUpdatedTrip(current, updated);
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  void _emitUpdatedTrip(TripsLoaded current, OperationTrip updated) {
    final trips = current.trips
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    emit(
      current.copyWith(
        trips: trips,
        selectedTrip: current.selectedTrip?.id == updated.id
            ? updated
            : current.selectedTrip,
      ),
    );
  }
}
