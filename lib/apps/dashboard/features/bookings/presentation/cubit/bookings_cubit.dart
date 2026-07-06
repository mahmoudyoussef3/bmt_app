import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/operation_booking.dart';
import '../../domain/usecases/approve_booking_usecase.dart';
import '../../domain/usecases/bulk_approve_bookings_usecase.dart';
import '../../domain/usecases/bulk_reject_bookings_usecase.dart';
import '../../domain/usecases/get_operation_bookings_usecase.dart';
import '../../domain/usecases/reject_booking_usecase.dart';
import '../../domain/usecases/request_reupload_usecase.dart';
import '../../domain/usecases/watch_bookings_usecase.dart';
import '../models/booking_filters.dart';
import 'bookings_state.dart';

class BookingsCubit extends Cubit<BookingsState> {
  final GetOperationBookingsUseCase _getBookings;
  final ApproveBookingUseCase _approveBooking;
  final RejectBookingUseCase _rejectBooking;
  final RequestReuploadUseCase _requestReupload;
  final BulkApproveBookingsUseCase _bulkApprove;
  final BulkRejectBookingsUseCase _bulkReject;
  final WatchBookingsUseCase _watchBookings;

  StreamSubscription<List<OperationBooking>>? _bookingsSubscription;

  BookingsCubit({
    required GetOperationBookingsUseCase getBookings,
    required ApproveBookingUseCase approveBooking,
    required RejectBookingUseCase rejectBooking,
    required RequestReuploadUseCase requestReupload,
    required BulkApproveBookingsUseCase bulkApprove,
    required BulkRejectBookingsUseCase bulkReject,
    required WatchBookingsUseCase watchBookings,
  }) : _getBookings = getBookings,
       _approveBooking = approveBooking,
       _rejectBooking = rejectBooking,
       _requestReupload = requestReupload,
       _bulkApprove = bulkApprove,
       _bulkReject = bulkReject,
       _watchBookings = watchBookings,
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

  void switchTab(BookingStatus status) {
    final current = state;
    if (current is! BookingsLoaded) return;
    emit(current.copyWith(activeTab: status, selectedIds: const {}));
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

  void updateFilters(BookingFilters filters) {
    final current = state;
    if (current is! BookingsLoaded) return;
    emit(current.copyWith(filters: filters, selectedIds: const {}));
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

  Future<void> _runReview(
    Future<OperationBooking> Function() action,
  ) async {
    final current = state;
    if (current is! BookingsLoaded) return;
    try {
      final updated = await action();
      _emitUpdated(current, [updated]);
    } catch (error) {
      emit(BookingsError(error.toString()));
    }
  }

  Future<void> bulkApprove(String? note) async {
    final current = state;
    if (current is! BookingsLoaded || current.selectedIds.isEmpty) return;
    try {
      final updated = await _bulkApprove(current.selectedIds.toList(), note);
      _emitUpdated(current, updated, clearSelection: true);
    } catch (error) {
      emit(BookingsError(error.toString()));
    }
  }

  Future<void> bulkReject(String reason) async {
    final current = state;
    if (current is! BookingsLoaded || current.selectedIds.isEmpty) return;
    try {
      final updated = await _bulkReject(current.selectedIds.toList(), reason);
      _emitUpdated(current, updated, clearSelection: true);
    } catch (error) {
      emit(BookingsError(error.toString()));
    }
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
