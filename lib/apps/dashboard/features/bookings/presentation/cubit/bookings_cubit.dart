import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/operation_booking.dart';
import '../../domain/usecases/approve_booking_usecase.dart';
import '../../domain/usecases/assign_bookings_to_trip_usecase.dart';
import '../../domain/usecases/bulk_update_bookings_status_usecase.dart';
import '../../domain/usecases/get_operation_bookings_usecase.dart';
import '../../domain/usecases/reject_booking_usecase.dart';
import '../../domain/usecases/request_reupload_usecase.dart';
import '../../domain/usecases/update_booking_status_usecase.dart';
import '../../domain/usecases/watch_bookings_usecase.dart';
import '../models/booking_filters.dart';
import 'bookings_state.dart';

class BookingsCubit extends Cubit<BookingsState> {
  final GetOperationBookingsUseCase _getBookings;
  final UpdateBookingStatusUseCase _updateStatus;
  final BulkUpdateBookingsStatusUseCase _bulkUpdateStatus;
  final AssignBookingsToTripUseCase _assignToTrip;
  final ApproveBookingUseCase _approveBooking;
  final RejectBookingUseCase _rejectBooking;
  final RequestReuploadUseCase _requestReupload;
  final WatchBookingsUseCase _watchBookings;

  StreamSubscription<List<OperationBooking>>? _bookingsSubscription;

  BookingsCubit({
    required GetOperationBookingsUseCase getBookings,
    required UpdateBookingStatusUseCase updateStatus,
    required BulkUpdateBookingsStatusUseCase bulkUpdateStatus,
    required AssignBookingsToTripUseCase assignToTrip,
    required ApproveBookingUseCase approveBooking,
    required RejectBookingUseCase rejectBooking,
    required RequestReuploadUseCase requestReupload,
    required WatchBookingsUseCase watchBookings,
  }) : _getBookings = getBookings,
       _updateStatus = updateStatus,
       _bulkUpdateStatus = bulkUpdateStatus,
       _assignToTrip = assignToTrip,
       _approveBooking = approveBooking,
       _rejectBooking = rejectBooking,
       _requestReupload = requestReupload,
       _watchBookings = watchBookings,
       super(const BookingsLoading());

  Future<void> load() async {
    emit(const BookingsLoading());
    try {
      final bookings = await _getBookings();
      emit(BookingsLoaded(bookings: bookings, filters: const BookingFilters()));
      _bookingsSubscription?.cancel();
      _bookingsSubscription = _watchBookings().listen(_onRealtimeUpdate);
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

  Future<void> updateStatus(
    OperationBooking booking,
    BookingStatus status,
  ) async {
    final current = state;
    if (current is! BookingsLoaded) return;
    try {
      final updated = await _updateStatus(booking.id, status);
      _emitUpdated(current, [updated]);
    } catch (error) {
      emit(BookingsError(error.toString()));
    }
  }

  Future<void> approveBooking(String bookingId, String? note) async {
    final current = state;
    if (current is! BookingsLoaded) return;
    try {
      final updated = await _approveBooking(bookingId, 'خدمة العملاء', note);
      _emitUpdated(current, [updated]);
    } catch (error) {
      emit(BookingsError(error.toString()));
    }
  }

  Future<void> rejectBooking(
    String bookingId,
    String reason,
    String? note,
  ) async {
    final current = state;
    if (current is! BookingsLoaded) return;
    try {
      final updated = await _rejectBooking(
        bookingId,
        'خدمة العملاء',
        reason,
        note,
      );
      _emitUpdated(current, [updated]);
    } catch (error) {
      emit(BookingsError(error.toString()));
    }
  }

  Future<void> requestReupload(String bookingId, String reason) async {
    final current = state;
    if (current is! BookingsLoaded) return;
    try {
      final updated = await _requestReupload(
        bookingId,
        'خدمة العملاء',
        reason,
      );
      _emitUpdated(current, [updated]);
    } catch (error) {
      emit(BookingsError(error.toString()));
    }
  }

  Future<void> bulkUpdate(BookingStatus status) async {
    final current = state;
    if (current is! BookingsLoaded || current.selectedIds.isEmpty) return;
    try {
      final updated = await _bulkUpdateStatus(
        current.selectedIds.toList(),
        status,
      );
      _emitUpdated(current, updated, clearSelection: true);
    } catch (error) {
      emit(BookingsError(error.toString()));
    }
  }

  Future<void> assignSelectedToTrip(String tripId) async {
    final current = state;
    if (current is! BookingsLoaded || current.selectedIds.isEmpty) return;
    try {
      final updated = await _assignToTrip(current.selectedIds.toList(), tripId);
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
