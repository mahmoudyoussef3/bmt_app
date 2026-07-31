import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/operation_booking.dart';
import '../../domain/entities/reassignment_target.dart';
import '../../domain/usecases/approve_booking_usecase.dart';
import '../../domain/usecases/bulk_approve_bookings_usecase.dart';
import '../../domain/usecases/bulk_reject_bookings_usecase.dart';
import '../../domain/usecases/get_operation_bookings_usecase.dart';
import '../../domain/usecases/reassign_booking_usecase.dart';
import '../../domain/usecases/reject_booking_usecase.dart';
import '../../domain/usecases/request_reupload_usecase.dart';
import '../../domain/usecases/watch_bookings_usecase.dart';
import '../models/booking_filters.dart';
import '../models/booking_queue_tab.dart';
import '../models/booking_sort.dart';
import 'bookings_state.dart';

class BookingsCubit extends Cubit<BookingsState> {
  final GetOperationBookingsUseCase _getBookings;
  final ApproveBookingUseCase _approveBooking;
  final RejectBookingUseCase _rejectBooking;
  final RequestReuploadUseCase _requestReupload;
  final BulkApproveBookingsUseCase _bulkApprove;
  final BulkRejectBookingsUseCase _bulkReject;
  final WatchBookingsUseCase _watchBookings;
  final ReassignBookingUseCase _reassignBooking;
  final GetReassignmentTargetsUseCase _getReassignmentTargets;

  StreamSubscription<List<OperationBooking>>? _bookingsSubscription;

  BookingsCubit({
    required GetOperationBookingsUseCase getBookings,
    required ApproveBookingUseCase approveBooking,
    required RejectBookingUseCase rejectBooking,
    required RequestReuploadUseCase requestReupload,
    required BulkApproveBookingsUseCase bulkApprove,
    required BulkRejectBookingsUseCase bulkReject,
    required WatchBookingsUseCase watchBookings,
    required ReassignBookingUseCase reassignBooking,
    required GetReassignmentTargetsUseCase getReassignmentTargets,
  }) : _getBookings = getBookings,
       _approveBooking = approveBooking,
       _rejectBooking = rejectBooking,
       _requestReupload = requestReupload,
       _bulkApprove = bulkApprove,
       _bulkReject = bulkReject,
       _watchBookings = watchBookings,
       _reassignBooking = reassignBooking,
       _getReassignmentTargets = getReassignmentTargets,
       super(const BookingsLoading());

  Future<void> load() async {
    emit(const BookingsLoading());
    try {
      final bookings = await _getBookings();
      emit(BookingsLoaded(bookings: bookings, filters: const BookingFilters()));
      _bookingsSubscription?.cancel();
      // A transient realtime/refetch error must not tear down the live view or
      // replace the loaded list with an error screen; keep the last good data.
      _bookingsSubscription = _watchBookings().listen(
        _onRealtimeUpdate,
        onError: (_) {},
      );
    } catch (error) {
      emit(BookingsError(error.toString()));
    }
  }

  void _onRealtimeUpdate(List<OperationBooking> updatedBookings) {
    final current = state;
    if (current is! BookingsLoaded) return;
    final opened = current.openedBooking == null
        ? null
        : updatedBookings.firstWhere(
            (b) => b.id == current.openedBooking!.id,
            orElse: () => current.openedBooking!,
          );
    emit(current.copyWith(bookings: updatedBookings, openedBooking: opened));
  }

  @override
  Future<void> close() {
    _bookingsSubscription?.cancel();
    return super.close();
  }

  void switchTab(BookingQueueTab tab) {
    final current = state;
    if (current is! BookingsLoaded) return;
    emit(current.copyWith(activeTab: tab, selectedIds: const {}, page: 0));
  }

  /// Sorts by [field], flipping direction when the operator taps the column that
  /// is already sorted — the interaction every desktop table has.
  void sortBy(BookingSortField field) {
    final current = state;
    if (current is! BookingsLoaded) return;
    final sameField = current.sortField == field;
    emit(
      current.copyWith(
        sortField: field,
        // Dates read best newest-first and text best A→Z, so a fresh column
        // starts in the direction that column is normally read in.
        sortAscending: sameField
            ? !current.sortAscending
            : field == BookingSortField.passenger ||
                  field == BookingSortField.route,
        page: 0,
      ),
    );
  }

  void goToPage(int page) {
    final current = state;
    if (current is! BookingsLoaded) return;
    emit(current.copyWith(page: page));
  }

  void openBooking(OperationBooking booking) {
    final current = state;
    if (current is! BookingsLoaded) return;
    emit(current.copyWith(openedBooking: booking));
  }

  void closePanel() {
    final current = state;
    if (current is! BookingsLoaded) return;
    emit(current.copyWith(clearOpenedBooking: true));
  }

  void toggleSelection(String bookingId) {
    final current = state;
    if (current is! BookingsLoaded) return;
    final selected = {...current.selectedIds};
    selected.contains(bookingId)
        ? selected.remove(bookingId)
        : selected.add(bookingId);
    emit(current.copyWith(selectedIds: selected));
  }

  void clearSelection() {
    final current = state;
    if (current is! BookingsLoaded) return;
    emit(current.copyWith(selectedIds: const {}));
  }

  /// Selects (or clears) every reviewable row on the current page — the batch an
  /// operator means by "select all", rather than the whole unseen result set.
  void toggleSelectAllOnPage() {
    final current = state;
    if (current is! BookingsLoaded) return;
    final pageIds = current.selectablePageBookings.map((b) => b.id).toSet();
    if (pageIds.isEmpty) return;
    final selected = {...current.selectedIds};
    current.allPageSelected
        ? selected.removeAll(pageIds)
        : selected.addAll(pageIds);
    emit(current.copyWith(selectedIds: selected));
  }

  void updateFilters(BookingFilters filters) {
    final current = state;
    if (current is! BookingsLoaded) return;
    emit(current.copyWith(filters: filters, selectedIds: const {}, page: 0));
  }

  void clearFilters() {
    final current = state;
    if (current is! BookingsLoaded) return;
    emit(
      current.copyWith(
        filters: const BookingFilters(),
        selectedIds: const {},
        page: 0,
      ),
    );
  }

  Future<void> approveBooking(String bookingId, String? note) async {
    await _runReview(() => _approveBooking(bookingId, note));
  }

  Future<void> rejectBooking(String bookingId, String reason) async {
    await _runReview(() => _rejectBooking(bookingId, reason));
  }

  Future<void> requestReupload(String bookingId, String reason) async {
    await _runReview(() => _requestReupload(bookingId, reason));
  }

  /// Moves the booking onto [newTripId]. The old seat is released and a new one
  /// taken server-side, so the list is refreshed from the returned row.
  Future<void> reassignBooking(String bookingId, String newTripId) async {
    await _runReview(() => _reassignBooking(bookingId, newTripId));
  }

  /// Trips the opened booking can be moved to. Fetched on demand — the picker is
  /// rarely opened, so this is not worth holding in the list state.
  Future<List<ReassignmentTarget>> loadReassignmentTargets() {
    return _getReassignmentTargets();
  }

  Future<void> _runReview(Future<OperationBooking> Function() action) async {
    await _runAction((current) async {
      final updated = await action();
      _emitUpdated(current, [updated]);
    });
  }

  Future<void> bulkApprove(String? note) async {
    await _runAction((current) async {
      if (current.selectedIds.isEmpty) return;
      final updated = await _bulkApprove(current.selectedIds.toList(), note);
      _emitUpdated(current, updated, clearSelection: true);
    });
  }

  Future<void> bulkReject(String reason) async {
    await _runAction((current) async {
      if (current.selectedIds.isEmpty) return;
      final updated = await _bulkReject(current.selectedIds.toList(), reason);
      _emitUpdated(current, updated, clearSelection: true);
    });
  }

  /// Runs a mutating action, marking the workspace busy for its duration and
  /// reporting failures as a transient [BookingsLoaded.actionError].
  ///
  /// Deliberately never emits [BookingsError]: that state is for a failed
  /// *load*, when there is nothing to show. Dropping an operator back to a blank
  /// error page because one approval was rejected would discard their filters,
  /// their selection and the row they were working on.
  Future<void> _runAction(
    Future<void> Function(BookingsLoaded current) action,
  ) async {
    final current = state;
    if (current is! BookingsLoaded || current.isProcessing) return;
    emit(current.copyWith(isProcessing: true, clearActionError: true));
    try {
      await action(current);
    } catch (error) {
      final latest = state;
      final base = latest is BookingsLoaded ? latest : current;
      emit(
        base.copyWith(
          isProcessing: false,
          actionError: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return;
    }
    final latest = state;
    if (latest is BookingsLoaded && latest.isProcessing) {
      emit(latest.copyWith(isProcessing: false));
    }
  }

  void clearActionError() {
    final current = state;
    if (current is! BookingsLoaded || current.actionError == null) return;
    emit(current.copyWith(clearActionError: true));
  }

  void _emitUpdated(
    BookingsLoaded current,
    List<OperationBooking> updated, {
    bool clearSelection = false,
  }) {
    final updatedById = {for (final booking in updated) booking.id: booking};
    final bookings = current.bookings
        .map((booking) => updatedById[booking.id] ?? booking)
        .toList();
    final opened = current.openedBooking == null
        ? null
        : updatedById[current.openedBooking!.id] ?? current.openedBooking;
    emit(
      current.copyWith(
        bookings: bookings,
        openedBooking: opened,
        selectedIds: clearSelection ? const {} : current.selectedIds,
      ),
    );
  }
}
