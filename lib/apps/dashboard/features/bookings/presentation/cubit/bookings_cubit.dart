import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_filter_memory.dart';

import '../../domain/entities/operation_booking.dart';
import '../../domain/entities/reassignment_target.dart';
import '../../domain/usecases/add_booking_note_usecase.dart';
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
  final AddBookingNoteUseCase _addNote;

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
    required AddBookingNoteUseCase addNote,
  }) : _getBookings = getBookings,
       _approveBooking = approveBooking,
       _rejectBooking = rejectBooking,
       _requestReupload = requestReupload,
       _bulkApprove = bulkApprove,
       _bulkReject = bulkReject,
       _watchBookings = watchBookings,
       _reassignBooking = reassignBooking,
       _getReassignmentTargets = getReassignmentTargets,
       _addNote = addNote,
       super(const BookingsLoading());

  /// Loads the queue, optionally opening on [presetTab].
  ///
  /// [presetTab] is how `/payment-verification` survives as a destination now
  /// that مراجعة المدفوعات is a preset of this board rather than its own module:
  /// the route lands here on [BookingQueueTab.needsReview], which is the queue
  /// that screen was. It overrides remembered filters deliberately — an operator
  /// who asked for the payment queue is asking for *that* queue, not for
  /// whatever الحجوزات was last narrowed to.
  Future<void> load({BookingQueueTab? presetTab}) async {
    emit(const BookingsLoading());
    try {
      final bookings = await _getBookings();
      // The operator filtered this queue, opened a booking, and came back —
      // the shell built a new cubit, but their filter is still the one they
      // want. The filter bar shows its active count either way, so restoring
      // it cannot leave them reading a narrowed queue as the whole queue.
      emit(
        BookingsLoaded(
          bookings: bookings,
          activeTab: presetTab ?? BookingQueueTab.needsReview,
          filters: presetTab != null
              ? const BookingFilters()
              : DashboardFilterMemory.instance.read<BookingFilters>(
                      DashboardFilterIds.bookings,
                    ) ??
                    const BookingFilters(),
        ),
      );
      _bookingsSubscription?.cancel();
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
    DashboardFilterMemory.instance.write(DashboardFilterIds.bookings, filters);
    emit(current.copyWith(filters: filters, selectedIds: const {}, page: 0));
  }

  void clearFilters() {
    final current = state;
    if (current is! BookingsLoaded) return;
    // Forget rather than remember an empty filter: "I cleared this" has to
    // survive navigation exactly as a selection does.
    DashboardFilterMemory.instance.forget(DashboardFilterIds.bookings);
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

  /// Records an operator note against a booking, deciding nothing.
  ///
  /// Runs through the same action path as a review, so it marks the workspace
  /// busy and reports failure as a snackbar rather than as an error screen —
  /// losing a filtered queue because a note did not save is not a trade the
  /// operator would make.
  Future<void> addNote(String bookingId, String note) async {
    await _runReview(() => _addNote(bookingId, note));
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
