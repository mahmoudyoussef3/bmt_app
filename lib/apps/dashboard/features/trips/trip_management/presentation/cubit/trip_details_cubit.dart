import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/domain/entities/operation_trip.dart';
import '../../domain/usecases/trip_management_usecases.dart';

enum TripWorkspaceTab {
  overview,
  passengers,
  seats,
  pricing,
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
  final bool isSaving;
  final String? lastError;

  const TripDetailsLoaded({
    required this.trip,
    this.tab = TripWorkspaceTab.overview,
    this.isSaving = false,
    this.lastError,
  });

  TripDetailsLoaded copyWith({
    OperationTrip? trip,
    TripWorkspaceTab? tab,
    bool? isSaving,
    String? lastError,
    bool clearError = false,
  }) {
    return TripDetailsLoaded(
      trip: trip ?? this.trip,
      tab: tab ?? this.tab,
      isSaving: isSaving ?? this.isSaving,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }
}

class TripDetailsCubit extends Cubit<TripDetailsState> {
  final GetTripDetailsUseCase _getTripDetails;
  final UpdateTripStatusUseCase _updateTripStatus;
  final UpdateTripInfoUseCase _updateTripInfo;
  final WatchTripDetailsUseCase _watchTripDetails;

  StreamSubscription<void>? _tripSub;
  Timer? _refreshTimer;
  Timer? _realtimeRefreshDebounce;
  bool _refreshingFromSource = false;

  TripDetailsCubit({
    required GetTripDetailsUseCase getTripDetails,
    required UpdateTripStatusUseCase updateTripStatus,
    required UpdateTripInfoUseCase updateTripInfo,
    required WatchTripDetailsUseCase watchTripDetails,
  }) : _getTripDetails = getTripDetails,
       _updateTripStatus = updateTripStatus,
       _updateTripInfo = updateTripInfo,
       _watchTripDetails = watchTripDetails,
       super(const TripDetailsInitial());

  @override
  Future<void> close() {
    _cancelRealtimeSync();
    return super.close();
  }

  Future<void> showDetails(OperationTrip trip) async {
    emit(TripDetailsLoaded(trip: trip));
    _subscribeToChanges(trip.id);
    _startPeriodicRefresh();
  }

  void closeDetails() {
    _cancelRealtimeSync();
    emit(const TripDetailsInitial());
  }

  void changeWorkspaceTab(TripWorkspaceTab tab) {
    final current = state;
    if (current is! TripDetailsLoaded) return;
    emit(current.copyWith(tab: tab, clearError: true));
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
    emit(current.copyWith(isSaving: true, clearError: true));
    try {
      final updated = await _updateTripStatus(current.trip.id, status);
      emit(TripDetailsLoaded(trip: updated, tab: current.tab));
      return updated;
    } catch (e) {
      emit(current.copyWith(isSaving: false, lastError: _cleanError(e)));
      return null;
    }
  }

  Future<OperationTrip?> updateInfo(OperationTrip updatedTrip) async {
    final current = state;
    if (current is! TripDetailsLoaded) return null;
    emit(current.copyWith(isSaving: true, clearError: true));
    try {
      final updated = await _updateTripInfo(updatedTrip);
      emit(TripDetailsLoaded(trip: updated, tab: current.tab));
      return updated;
    } catch (e) {
      emit(current.copyWith(isSaving: false, lastError: _cleanError(e)));
      return null;
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception: ?'), '');
  }

  // ── realtime sync ──────────────────────────────────────────────────────

  void _subscribeToChanges(String tripId) {
    _tripSub?.cancel();
    _tripSub = _watchTripDetails(tripId).listen((_) {
      _realtimeRefreshDebounce?.cancel();
      _realtimeRefreshDebounce = Timer(
        const Duration(milliseconds: 250),
        _refreshFromSource,
      );
    }, onError: (_) {});
  }

  // Refresh the open trip every 30 s as a fallback in case a realtime event
  // is missed (matches live_trips_cubit's periodic safety net).
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _refreshFromSource();
    });
  }

  void _cancelRealtimeSync() {
    _tripSub?.cancel();
    _tripSub = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = null;
  }

  // Silent background refresh triggered by realtime/periodic sync. Unlike
  // refreshDetails(), it preserves the last loaded trip instead of surfacing
  // an error state if a transient background refetch fails.
  Future<void> _refreshFromSource() async {
    if (_refreshingFromSource || state is! TripDetailsLoaded) return;
    _refreshingFromSource = true;
    try {
      final current = state as TripDetailsLoaded;
      final updated = await _getTripDetails(current.trip.id);
      final latest = state;
      if (latest is! TripDetailsLoaded) return;
      emit(latest.copyWith(trip: updated));
    } catch (_) {
      // Preserve the last loaded trip if a background refresh fails.
    } finally {
      _refreshingFromSource = false;
    }
  }
}
