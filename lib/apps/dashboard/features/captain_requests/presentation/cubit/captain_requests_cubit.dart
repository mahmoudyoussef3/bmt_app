import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/captain_request.dart';
import '../../domain/usecases/captain_requests_usecases.dart';
import '../models/captain_request_queue_tab.dart';
import '../models/captain_request_sort.dart';
import 'captain_requests_state.dart';

class CaptainRequestsCubit extends Cubit<CaptainRequestsState> {
  final GetCaptainRequestsUseCase _getRequests;
  final WatchCaptainRequestsUseCase _watchRequests;
  final ApproveCaptainRequestUseCase _approve;
  final RejectCaptainRequestUseCase _reject;

  StreamSubscription<List<CaptainRequest>>? _sub;

  CaptainRequestsCubit({
    required GetCaptainRequestsUseCase getRequests,
    required WatchCaptainRequestsUseCase watchRequests,
    required ApproveCaptainRequestUseCase approve,
    required RejectCaptainRequestUseCase reject,
  }) : _getRequests = getRequests,
       _watchRequests = watchRequests,
       _approve = approve,
       _reject = reject,
       super(const CaptainRequestsLoading());

  Future<void> load() async {
    emit(const CaptainRequestsLoading());
    try {
      emit(CaptainRequestsLoaded(requests: await _getRequests()));
      _listen();
    } catch (e) {
      emit(CaptainRequestsError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _listen() {
    _sub?.cancel();
    _sub = _watchRequests().listen((requests) {
      final current = state;
      // Rebuild *from* the current state rather than fresh: a realtime row
      // arriving while the operator has a queue open and a search typed must
      // not silently reset them to the module's defaults.
      emit(
        current is CaptainRequestsLoaded
            ? current.copyWith(
                requests: requests,
                actionError: current.actionError,
              )
            : CaptainRequestsLoaded(requests: requests),
      );
    }, onError: (_) {});
  }

  /// Opens one queue. The tab sets the status filter and nothing else, so the
  /// operator's search survives the switch.
  void switchTab(CaptainRequestQueueTab tab) {
    final current = state;
    if (current is! CaptainRequestsLoaded) return;
    final status = tab.status;
    emit(
      status == null
          ? current.copyWith(clearStatusFilter: true)
          : current.copyWith(filterStatus: status),
    );
  }

  void setSearchQuery(String value) {
    final current = state;
    if (current is! CaptainRequestsLoaded) return;
    emit(current.copyWith(searchQuery: value));
  }

  /// Sets the ordering, flipping the direction when handed the key already in
  /// force — which is what tapping a sorted column header means.
  void setSort(CaptainRequestSort sort) {
    final current = state;
    if (current is! CaptainRequestsLoaded) return;
    emit(
      current.sort == sort
          ? current.copyWith(sortAscending: !current.sortAscending)
          : current.copyWith(sort: sort, sortAscending: false),
    );
  }

  void setFilterWindow(CaptainRequestWindow window) {
    final current = state;
    if (current is! CaptainRequestsLoaded) return;
    emit(current.copyWith(filterWindow: window));
  }

  void clearFilters() {
    final current = state;
    if (current is! CaptainRequestsLoaded) return;
    emit(
      current.copyWith(searchQuery: '', filterWindow: CaptainRequestWindow.all),
    );
  }

  /// Marks the request approved and links the driver just created for it.
  /// Returns an error message on failure, or null on success.
  Future<String?> approve({
    required String requestId,
    required String driverId,
  }) async {
    try {
      await _approve(requestId: requestId, driverId: driverId);
      await _refresh();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<void> reject({
    required String requestId,
    required String reason,
  }) async {
    try {
      await _reject(requestId: requestId, reason: reason);
      await _refresh();
    } catch (e) {
      final current = state;
      if (current is CaptainRequestsLoaded) {
        emit(
          current.copyWith(
            actionError: e.toString().replaceAll('Exception: ', ''),
          ),
        );
      }
    }
  }

  Future<void> _refresh() async {
    try {
      final requests = await _getRequests();
      final current = state;
      if (current is CaptainRequestsLoaded) {
        emit(current.copyWith(requests: requests));
      } else {
        emit(CaptainRequestsLoaded(requests: requests));
      }
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
