import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/bookings/data/datasources/mock_bookings_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/data/models/operation_booking_model.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/data/repositories/bookings_repository_impl.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/assign_bookings_to_trip_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/bulk_update_bookings_status_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/get_operation_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/update_booking_status_usecase.dart';

void main() {
  group('Bookings clean architecture chain', () {
    test('loads booking queue dummy data', () async {
      final repository = BookingsRepositoryImpl(MockBookingsDatasource());
      final getBookings = GetOperationBookingsUseCase(repository);

      final bookings = await getBookings();

      expect(bookings, isNotEmpty);
      expect(bookings.first.passengerName, 'سارة أحمد');
      expect(
        bookings.map((booking) => booking.status),
        contains(BookingStatus.newRequest),
      );
      expect(bookings.first.attachments, isNotEmpty);
    });

    test('updates booking status and appends history', () async {
      final repository = BookingsRepositoryImpl(MockBookingsDatasource());
      final getBookings = GetOperationBookingsUseCase(repository);
      final updateStatus = UpdateBookingStatusUseCase(repository);

      final booking = (await getBookings()).first;
      final updated = await updateStatus(booking.id, BookingStatus.confirmed);

      expect(updated.status, BookingStatus.confirmed);
      expect(updated.history.first, contains('مؤكدة'));
    });

    test('bulk approves and assigns selected bookings', () async {
      final repository = BookingsRepositoryImpl(MockBookingsDatasource());
      final getBookings = GetOperationBookingsUseCase(repository);
      final bulkUpdate = BulkUpdateBookingsStatusUseCase(repository);
      final assign = AssignBookingsToTripUseCase(repository);

      final ids = (await getBookings())
          .take(2)
          .map((booking) => booking.id)
          .toList();
      final confirmed = await bulkUpdate(ids, BookingStatus.confirmed);
      expect(
        confirmed.every((booking) => booking.status == BookingStatus.confirmed),
        isTrue,
      );

      final assigned = await assign(ids, 'TR-224');
      expect(
        assigned.every((booking) => booking.assignedTrip == 'TR-224'),
        isTrue,
      );
    });

    test('maps datasource failures to Arabic repository error', () {
      final repository = BookingsRepositoryImpl(_FailingBookingsDatasource());
      final getBookings = GetOperationBookingsUseCase(repository);

      expect(
        getBookings.call,
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('تعذر تحميل الحجوزات'),
          ),
        ),
      );
    });
  });
}

class _FailingBookingsDatasource implements BookingsDatasource {
  @override
  Future<List<OperationBookingModel>> assignToTrip(
    List<String> bookingIds,
    String tripId,
  ) {
    throw StateError('failure');
  }

  @override
  Future<List<OperationBookingModel>> bulkUpdateStatus(
    List<String> bookingIds,
    BookingStatus status,
  ) {
    throw StateError('failure');
  }

  @override
  Future<List<OperationBookingModel>> fetchBookings() {
    throw StateError('failure');
  }

  @override
  Future<OperationBookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) {
    throw StateError('failure');
  }
}
