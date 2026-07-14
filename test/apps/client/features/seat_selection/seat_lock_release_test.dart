import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/seat_selection/data/datasources/seat_selection_datasource.dart';
import 'package:bmt_app/apps/client/features/seat_selection/data/models/seat_selection_model.dart';
import 'package:bmt_app/apps/client/features/seat_selection/data/repositories/seat_selection_repository_impl.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/lock_trip_seat_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/release_trip_seat_lock_usecase.dart';

/// The seat lock commits in its own transaction, so a confirm that throws
/// afterwards leaves the seat reserved-but-unbooked. Nothing on the server
/// reclaims it (the expired-hold sweeper only walks seats reachable from a
/// booking row), so the client owes the seat a compensating release.
void main() {
  group('Seat lock compensation after a failed confirm', () {
    late _FakeSeatSelectionDatasource datasource;
    late SeatSelectionRepositoryImpl repository;

    setUp(() {
      datasource = _FakeSeatSelectionDatasource();
      repository = SeatSelectionRepositoryImpl(datasource);
    });

    test('duplicate_active_booking leaves no seat stranded', () async {
      datasource.hasActiveBookingOnTrip = true;

      await expectLater(
        LockTripSeatUseCase(repository)(tripId: 'trip-1', seatId: 'seat-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'reason',
            contains('duplicate_active_booking'),
          ),
        ),
      );

      // The seat is refused before it is ever locked — a passenger who retries
      // still sees it as bookable instead of held by their own dead attempt.
      expect(datasource.seatState, 'available');
    });

    test('a confirm failure hands the lock back', () async {
      await LockTripSeatUseCase(repository)(tripId: 'trip-1', seatId: 'seat-1');
      expect(datasource.seatState, 'reserved');

      datasource.confirmFailure = 'trip_not_available';
      await expectLater(
        repository.confirmSeatBooking(const {}),
        throwsA(isA<Exception>()),
      );

      // Without this the seat sits reserved until its lock expires, and the
      // seat map paints it as taken the whole time.
      expect(datasource.seatState, 'reserved');
      await ReleaseTripSeatLockUseCase(repository)(
        tripId: 'trip-1',
        seatId: 'seat-1',
      );
      expect(datasource.seatState, 'available');
    });

    test('release never frees a seat that already carries a booking', () async {
      await LockTripSeatUseCase(repository)(tripId: 'trip-1', seatId: 'seat-1');
      await repository.confirmSeatBooking(const {});
      expect(datasource.seatState, 'reserved');

      // Mirrors the card-payment path: the booking exists, the passenger just
      // did not finish paying. Releasing here would give their seat away.
      await ReleaseTripSeatLockUseCase(repository)(
        tripId: 'trip-1',
        seatId: 'seat-1',
      );

      expect(datasource.seatState, 'reserved');
    });
  });
}

/// Models the slice of `trip_seats` / `operation_bookings` that the seat RPCs
/// touch: a lock reserves the seat, a confirm attaches a booking to it, and a
/// release only frees a lock that no booking is standing on.
class _FakeSeatSelectionDatasource implements SeatSelectionDatasource {
  String seatState = 'available';
  bool seatHasBooking = false;
  bool hasActiveBookingOnTrip = false;
  String? confirmFailure;

  @override
  Future<Map<String, dynamic>> lockTripSeat({
    required String tripId,
    required String seatId,
  }) async {
    if (hasActiveBookingOnTrip) throw Exception('duplicate_active_booking');
    if (seatState != 'available') throw Exception('seat_unavailable');
    seatState = 'reserved';
    return {'success': true, 'seat_id': seatId};
  }

  @override
  Future<Map<String, dynamic>> confirmSeatBooking(
    Map<String, dynamic> params,
  ) async {
    if (confirmFailure != null) throw Exception(confirmFailure);
    seatHasBooking = true;
    return {'success': true, 'booking_id': 'booking-1'};
  }

  @override
  Future<void> releaseTripSeatLock({
    required String tripId,
    required String seatId,
  }) async {
    if (seatState == 'reserved' && !seatHasBooking) seatState = 'available';
  }

  @override
  Future<SeatSelectionModel> getSeatSelectionData(String tripId) =>
      throw UnimplementedError();

  @override
  @Deprecated('Use lockTripSeat + confirmSeatBooking instead')
  Future<String> bookTripSeat(Map<String, dynamic> params) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> updateExistingBookingPayment(
    Map<String, dynamic> params,
  ) => throw UnimplementedError();
}
