import 'package:flutter_test/flutter_test.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/repositories/bookings_repository.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/approve_booking_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/bulk_approve_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/bulk_reject_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/get_operation_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/reject_booking_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/request_reupload_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/watch_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/cubit/bookings_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/cubit/bookings_state.dart';

OperationBooking _booking(
  String id, {
  String clientId = 'c-1',
  BookingStatus status = BookingStatus.reserved,
  PaymentStatus paymentStatus = PaymentStatus.submitted,
}) {
  return OperationBooking(
    id: id,
    bookingNumber: 'BK-$id',
    clientId: clientId,
    passengerName: 'Passenger $id',
    phone: '0100',
    route: 'A - B',
    tripTime: '08:00',
    date: '2026-07-10',
    seat: 'A1',
    paymentMethod: BookingPaymentMethod.instaPay,
    status: status,
    paymentStatus: paymentStatus,
    paymentAmount: 100,
    packageName: 'pkg',
    createdAt: DateTime(2026, 7, 6),
    tripDetails: BookingTripDetails.empty,
    notes: const [],
    timeline: const [],
  );
}

class _FakeRepo implements BookingsRepository {
  _FakeRepo(this.seed);
  List<OperationBooking> seed;

  @override
  Future<List<OperationBooking>> getBookings() async => seed;

  @override
  Future<OperationBooking> approveBooking(String id, String? note) async =>
      _booking(id, status: BookingStatus.confirmed, paymentStatus: PaymentStatus.approved);

  @override
  Future<OperationBooking> rejectBooking(String id, String reason) async =>
      _booking(id, status: BookingStatus.cancelled, paymentStatus: PaymentStatus.rejected);

  @override
  Future<OperationBooking> requestReupload(String id, String reason) async =>
      _booking(id, paymentStatus: PaymentStatus.underReview);

  @override
  Future<List<OperationBooking>> bulkApprove(List<String> ids, String? n) async =>
      [for (final id in ids) await approveBooking(id, n)];

  @override
  Future<List<OperationBooking>> bulkReject(List<String> ids, String r) async =>
      [for (final id in ids) await rejectBooking(id, r)];

  @override
  Stream<List<OperationBooking>> watchBookings() => const Stream.empty();
}

BookingsCubit _cubit(_FakeRepo repo) {
  return BookingsCubit(
    getBookings: GetOperationBookingsUseCase(repo),
    approveBooking: ApproveBookingUseCase(repo),
    rejectBooking: RejectBookingUseCase(repo),
    requestReupload: RequestReuploadUseCase(repo),
    bulkApprove: BulkApproveBookingsUseCase(repo),
    bulkReject: BulkRejectBookingsUseCase(repo),
    watchBookings: WatchBookingsUseCase(repo),
  );
}

void main() {
  group('BookingsCubit', () {
    test('load emits BookingsLoaded with the fetched bookings', () async {
      final cubit = _cubit(_FakeRepo([_booking('1'), _booking('2')]));
      await cubit.load();

      final state = cubit.state;
      expect(state, isA<BookingsLoaded>());
      expect((state as BookingsLoaded).bookings.length, 2);
      await cubit.close();
    });

    test('approveBooking replaces the row with the approved result', () async {
      final cubit = _cubit(_FakeRepo([_booking('1')]));
      await cubit.load();

      await cubit.approveBooking('1', null);
      final state = cubit.state as BookingsLoaded;
      expect(state.bookings.single.status, BookingStatus.confirmed);
      expect(state.bookings.single.paymentStatus, PaymentStatus.approved);
      await cubit.close();
    });

    test('bulkApprove approves every selected booking and clears selection', () async {
      final cubit = _cubit(_FakeRepo([_booking('1'), _booking('2')]));
      await cubit.load();

      cubit.toggleSelection('1');
      cubit.toggleSelection('2');
      await cubit.bulkApprove(null);

      final state = cubit.state as BookingsLoaded;
      expect(state.selectedIds, isEmpty);
      expect(
        state.bookings.every((b) => b.status == BookingStatus.confirmed),
        isTrue,
      );
      await cubit.close();
    });

    test('bookingsForClient counts every booking a client has made', () async {
      final cubit = _cubit(
        _FakeRepo([
          _booking('1', clientId: 'c-1'),
          _booking('2', clientId: 'c-1'),
          _booking('3', clientId: 'c-2'),
        ]),
      );
      await cubit.load();

      final state = cubit.state as BookingsLoaded;
      expect(state.bookingsForClient('c-1'), 2);
      expect(state.bookingsForClient('c-2'), 1);
      await cubit.close();
    });
  });
}
