import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/domain/entities/operation_trip.dart';
import '../../domain/usecases/trip_management_usecases.dart';

enum TripWorkspaceTab {
  overview,
  passengers,
  seats,
  pricing,
  packages,
  payments,
  history,
}

sealed class TripDetailsState {
  const TripDetailsState();
}

class TripDetailsInitial extends TripDetailsState {
  const TripDetailsInitial();
}

class TripDetailsLoading extends TripDetailsState {
  const TripDetailsLoading();
}

class TripDetailsError extends TripDetailsState {
  final String message;
  const TripDetailsError(this.message);
}

class TripDetailsLoaded extends TripDetailsState {
  final OperationTrip trip;
  final TripWorkspaceTab tab;

  const TripDetailsLoaded({
    required this.trip,
    this.tab = TripWorkspaceTab.overview,
  });

  TripDetailsLoaded copyWith({
    OperationTrip? trip,
    TripWorkspaceTab? tab,
  }) {
    return TripDetailsLoaded(
      trip: trip ?? this.trip,
      tab: tab ?? this.tab,
    );
  }
}

class TripDetailsCubit extends Cubit<TripDetailsState> {
  final GetTripDetailsUseCase _getTripDetails;
  final UpdateTripStatusUseCase _updateTripStatus;
  final UpdateTripInfoUseCase _updateTripInfo;

  TripDetailsCubit({
    required GetTripDetailsUseCase getTripDetails,
    required UpdateTripStatusUseCase updateTripStatus,
    required UpdateTripInfoUseCase updateTripInfo,
  })  : _getTripDetails = getTripDetails,
        _updateTripStatus = updateTripStatus,
        _updateTripInfo = updateTripInfo,
        super(const TripDetailsInitial());

  Future<void> showDetails(OperationTrip trip) async {
    emit(TripDetailsLoaded(trip: trip));
  }

  void closeDetails() {
    emit(const TripDetailsInitial());
  }

  void changeWorkspaceTab(TripWorkspaceTab tab) {
    final current = state;
    if (current is! TripDetailsLoaded) return;
    emit(current.copyWith(tab: tab));
  }

  Future<void> refreshDetails() async {
    final current = state;
    if (current is! TripDetailsLoaded) return;
    try {
      final updated = await _getTripDetails(current.trip.id);
      emit(current.copyWith(trip: updated));
    } catch (e) {
      emit(TripDetailsError(e.toString()));
    }
  }

  void updateTripLocally(OperationTrip updated) {
    final current = state;
    if (current is! TripDetailsLoaded) return;
    emit(current.copyWith(trip: updated));
  }

  Future<OperationTrip?> updateStatus(OperationTripStatus status) async {
    final current = state;
    if (current is! TripDetailsLoaded) return null;
    emit(const TripDetailsLoading());
    try {
      final updated = await _updateTripStatus(current.trip.id, status);
      emit(TripDetailsLoaded(trip: updated, tab: current.tab));
      return updated;
    } catch (e) {
      emit(TripDetailsError(e.toString()));
      return null;
    }
  }

  Future<OperationTrip?> updateInfo(OperationTrip updatedTrip) async {
    final current = state;
    if (current is! TripDetailsLoaded) return null;
    emit(const TripDetailsLoading());
    try {
      final updated = await _updateTripInfo(updatedTrip);
      emit(TripDetailsLoaded(trip: updated, tab: current.tab));
      return updated;
    } catch (e) {
      emit(TripDetailsError(e.toString()));
      return null;
    }
  }
}
