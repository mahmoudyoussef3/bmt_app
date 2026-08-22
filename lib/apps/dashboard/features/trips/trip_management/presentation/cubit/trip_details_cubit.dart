import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_lifecycle.dart';
import '../../domain/usecases/trip_management_usecases.dart';

enum TripWorkspaceTab { overview, passengers, seats, pricing, history }

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
  final CancelTripUseCase _cancelTrip;
  final CloseStaleTripUseCase _closeStaleTrip;
  final WatchTripDetailsUseCase _watchTripDetails;

  StreamSubscription<void>? _tripSub;
  Timer? _refreshTimer;
  Timer? _realtimeRefreshDebounce;
  bool _refreshingFromSource = false;

  TripDetailsCubit({
    required GetTripDetailsUseCase getTripDetails,
    required UpdateTripStatusUseCase updateTripStatus,
    required UpdateTripInfoUseCase updateTripInfo,
    required CancelTripUseCase cancelTrip,
    required CloseStaleTripUseCase closeStaleTrip,
    required WatchTripDetailsUseCase watchTripDetails,
  }) : _getTripDetails = getTripDetails,
       _updateTripStatus = updateTripStatus,
       _updateTripInfo = updateTripInfo,
       _cancelTrip = cancelTrip,
       _closeStaleTrip = closeStaleTrip,
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

  Future<OperationTrip?> updateStatus(
    OperationTripStatus status, {
    String? reason,
  }) async {
    return _run((tripId) => _updateTripStatus(tripId, status, reason: reason));
  }

  /// Cancels the open trip. [reason] is always carried: the server refuses a
  /// reasonless cancellation once boarding has started, and the reason is written into
  /// the trip's event log either way.
  Future<OperationTrip?> cancelTrip(String reason) async {
    return _run((tripId) => _cancelTrip(tripId, reason));
  }

  /// Closes a trip whose departure day has passed while it was still open.
  Future<OperationTrip?> closeStaleTrip(
    StaleTripOutcome outcome, {
    String? reason,
  }) async {
    return _run((tripId) => _closeStaleTrip(tripId, outcome, reason: reason));
  }

  /// One saving/error envelope for every lifecycle action, so a failure always leaves
  /// the workspace on the trip it was showing with the server's own explanation
  /// attached — rather than dropping the reason and letting the screen say only that
  /// something went wrong.
  Future<OperationTrip?> _run(
    Future<OperationTrip> Function(String tripId) action,
  ) async {
    final current = state;
    if (current is! TripDetailsLoaded) return null;
    emit(current.copyWith(isSaving: true, clearError: true));
    try {
      final updated = await action(current.trip.id);
      emit(TripDetailsLoaded(trip: updated, tab: current.tab));
      return updated;
    } catch (e) {
      emit(current.copyWith(isSaving: false, lastError: _cleanError(e)));
      return null;
    }
  }

  Future<OperationTrip?> updateInfo(OperationTrip updatedTrip) async {
    return _run((_) => _updateTripInfo(updatedTrip));
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception: ?'), '');
  }

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
    } finally {
      _refreshingFromSource = false;
    }
  }
}
