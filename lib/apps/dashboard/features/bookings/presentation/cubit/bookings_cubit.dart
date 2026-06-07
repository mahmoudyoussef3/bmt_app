import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/operation_booking.dart';
import '../../domain/usecases/assign_bookings_to_trip_usecase.dart';
import '../../domain/usecases/bulk_update_bookings_status_usecase.dart';
import '../../domain/usecases/get_operation_bookings_usecase.dart';
import '../../domain/usecases/update_booking_status_usecase.dart';
import '../models/booking_filters.dart';
import 'bookings_state.dart';

class BookingsCubit extends Cubit<BookingsState> {
  final GetOperationBookingsUseCase _getBookings;
  final UpdateBookingStatusUseCase _updateStatus;
  final BulkUpdateBookingsStatusUseCase _bulkUpdateStatus;
  final AssignBookingsToTripUseCase _assignToTrip;

  BookingsCubit({
    required GetOperationBookingsUseCase getBookings,
    required UpdateBookingStatusUseCase updateStatus,
    required BulkUpdateBookingsStatusUseCase bulkUpdateStatus,
    required AssignBookingsToTripUseCase assignToTrip,
  }) : _getBookings = getBookings,
       _updateStatus = updateStatus,
       _bulkUpdateStatus = bulkUpdateStatus,
       _assignToTrip = assignToTrip,
       super(const BookingsLoading());

  Future<void> load() async {
    emit(const BookingsLoading());
    try {
      final bookings = await _getBookings();
      emit(BookingsLoaded(bookings: bookings, filters: const BookingFilters()));
    } catch (error) {
      emit(BookingsError(error.toString()));
    }
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
