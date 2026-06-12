import 'package:bmt_app/apps/dashboard/features/bookings/data/datasources/bookings_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

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
      final repository = BookingsRepositoryImpl(_DummyBookingsDatasource());
      final getBookings = GetOperationBookingsUseCase(repository);

      final bookings = await getBookings();

      expect(bookings, isNotEmpty);
      expect(bookings.first.passengerName, isNotEmpty);
      expect(
        bookings.map((booking) => booking.status),
        contains(BookingStatus.newRequest),
      );
      expect(bookings.first.attachments, isNotEmpty);
    });

    test('updates booking status and appends history', () async {
      final repository = BookingsRepositoryImpl(_DummyBookingsDatasource());
      final getBookings = GetOperationBookingsUseCase(repository);
      final updateStatus = UpdateBookingStatusUseCase(repository);

      final booking = (await getBookings()).first;
      final updated = await updateStatus(booking.id, BookingStatus.confirmed);

      expect(updated.status, BookingStatus.confirmed);
      expect(updated.timeline.first.action, contains('مؤكد المقعد'));
    });

    test('bulk approves and assigns selected bookings', () async {
      final repository = BookingsRepositoryImpl(_DummyBookingsDatasource());
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

class _DummyBookingsDatasource implements BookingsDatasource {
  final _dummyBooking = OperationBookingModel(
    id: 'B-1001',
    passengerName: 'Test Passenger',
    phone: '01000000000',
    route: 'Route 1',
    tripTime: '10:00',
    date: 'Today',
    seat: '1',
    paymentMethod: BookingPaymentMethod.cash,
    status: BookingStatus.newRequest,
    priority: BookingPriority.normal,
    assignedTrip: 'TR-100',
    createdAt: DateTime.now(),
    customerProfile: const BookingCustomerProfileModel(
      name: 'Test Passenger',
      phone: '01000000000',
      email: 'test@example.com',
      tripsCount: '1',
      accountStatus: 'Active',
    ),
    tripDetails: const BookingTripDetailsModel(
      route: 'Route 1',
      date: 'Today',
      time: '10:00',
      vehicle: 'Car 1',
      driver: 'Driver 1',
    ),
    paymentDetails: const BookingPaymentDetailsModel(
      amount: '100',
      method: BookingPaymentMethod.cash,
      status: 'Paid',
      reference: 'REF-1',
    ),
    attachments: const ['receipt.jpg'],
    notes: const [],
    timeline: [
      BookingTimelineEventModel(
        timestamp: DateTime.now(),
        action: 'Created',
        actor: 'System',
      )
    ],
  );

  @override
  Future<List<OperationBookingModel>> assignToTrip(
    List<String> bookingIds,
    String tripId,
  ) async {
    return bookingIds.map((id) => OperationBookingModel.fromEntity(_dummyBooking.copyWith(
      id: id,
      assignedTrip: tripId,
    ))).toList();
  }

  @override
  Future<List<OperationBookingModel>> bulkUpdateStatus(
    List<String> bookingIds,
    BookingStatus status,
  ) async {
    return bookingIds.map((id) => OperationBookingModel.fromEntity(_dummyBooking.copyWith(
      id: id,
      status: status,
    ))).toList();
  }

  @override
  Future<List<OperationBookingModel>> fetchBookings() async {
    return [
      _dummyBooking,
      OperationBookingModel.fromEntity(_dummyBooking.copyWith(id: 'B-1002')),
    ];
  }

  @override
  Future<OperationBookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    return OperationBookingModel.fromEntity(_dummyBooking.copyWith(
      id: bookingId,
      status: status,
      timeline: [
        BookingTimelineEventModel(
          timestamp: DateTime.now(),
          action: 'مؤكد المقعد',
          actor: 'النظام',
        )
      ],
    ));
  }

  @override
  Future<OperationBookingModel> approveBooking(
    String bookingId,
    String reviewer,
    String? note,
  ) async {
    return _dummyBooking;
  }

  @override
  Future<OperationBookingModel> rejectBooking(
    String bookingId,
    String reviewer,
    String reason,
    String? note,
  ) async {
    return _dummyBooking;
  }

  @override
  Future<OperationBookingModel> requestReupload(
    String bookingId,
    String reviewer,
    String reason,
  ) async {
    return _dummyBooking;
  }
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

  @override
  Future<OperationBookingModel> approveBooking(
    String bookingId,
    String reviewer,
    String? note,
  ) {
    throw StateError('failure');
  }

  @override
  Future<OperationBookingModel> rejectBooking(
    String bookingId,
    String reviewer,
    String reason,
    String? note,
  ) {
    throw StateError('failure');
  }

  @override
  Future<OperationBookingModel> requestReupload(
    String bookingId,
    String reviewer,
    String reason,
  ) {
    throw StateError('failure');
  }
}
