import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/trips/data/mappers/trip_mapper.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';

/// The three state axes a booking has — journey, booking, payment — can and do
/// disagree. Before the [BookingState] axis existed the Client app rendered one
/// badge derived from the trip alone, so every one of these cases showed as a
/// plain "Upcoming" or "Completed" trip. Measured on the production database at
/// the time of the audit: 17 of 32 bookings sat at `reserved` / `pending` and
/// all of them claimed to be confirmed upcoming trips.
TripData _trip({
  TripStatus status = TripStatus.upcoming,
  BookingState bookingState = BookingState.reserved,
  PaymentStatus paymentStatus = PaymentStatus.underReview,
  String officeName = 'Banha Lines',
}) {
  return TripData(
    id: 'b1',
    reference: 'BMT-ABCD1234',
    status: status,
    bookingState: bookingState,
    pickup: 'Banha',
    destination: 'Smart Village',
    dateLabel: '2026-07-30',
    timeLabel: '08:00',
    driverName: 'Ahmed',
    driverPhone: '0100',
    driverInitials: 'AH',
    driverRating: 4.5,
    vehicleName: 'Coaster',
    vehicleType: 'Minibus',
    vehicleId: 'v1',
    seats: const ['A1'],
    paymentStatus: paymentStatus,
    fare: 'EGP 50',
    officeName: officeName,
  );
}

void main() {
  group('a held seat is not a confirmed trip', () {
    test('a reserved booking awaiting review says so, and is not the rider\'s '
        'move', () {
      final trip = _trip();

      expect(trip.attention, TripAttention.awaitingPaymentReview);
      expect(trip.needsRiderAction, isFalse);
      // The journey axis still reads "upcoming" — the point is that it is no
      // longer the only thing the rider is told.
      expect(trip.status, TripStatus.upcoming);
    });

    test('a card booking that never settled asks the rider to finish paying', () {
      final trip = _trip(paymentStatus: PaymentStatus.pending);

      expect(trip.attention, TripAttention.paymentIncomplete);
      expect(trip.needsRiderAction, isTrue);
    });

    test('a rejected payment on an open booking is surfaced, not hidden', () {
      final trip = _trip(paymentStatus: PaymentStatus.failed);

      expect(trip.attention, TripAttention.paymentRejected);
      expect(trip.needsRiderAction, isTrue);
    });
  });

  group('contradictions are named, not smoothed over', () {
    test('a trip completed over a booking that never confirmed needs support', () {
      final trip = _trip(
        status: TripStatus.completed,
        bookingState: BookingState.reserved,
      );

      // The rider did not travel on a seat that was only held. Claiming
      // "Completed" here is the lie this case exists to prevent.
      expect(trip.attention, TripAttention.needsSupport);
      expect(trip.canBeReviewed, isFalse);
    });

    test('an approved payment on a still-reserved booking needs support', () {
      final trip = _trip(paymentStatus: PaymentStatus.paid);

      expect(trip.attention, TripAttention.needsSupport);
    });

    test('a cancelled trip the rider already paid for is a refund', () {
      final trip = _trip(
        status: TripStatus.cancelled,
        bookingState: BookingState.confirmed,
        paymentStatus: PaymentStatus.paid,
      );

      expect(trip.attention, TripAttention.refundDue);
    });

    test('a booking cancelled before payment cleared owes nobody anything', () {
      final trip = _trip(
        bookingState: BookingState.cancelled,
        paymentStatus: PaymentStatus.underReview,
      );

      expect(trip.attention, TripAttention.none);
    });
  });

  group('a settled booking is quiet', () {
    test('a confirmed, paid, upcoming trip raises nothing', () {
      final trip = _trip(
        bookingState: BookingState.confirmed,
        paymentStatus: PaymentStatus.paid,
      );

      expect(trip.attention, TripAttention.none);
      expect(trip.needsRiderAction, isFalse);
    });

    test('a completed journey raises nothing', () {
      final trip = _trip(
        status: TripStatus.completed,
        bookingState: BookingState.completed,
        paymentStatus: PaymentStatus.paid,
      );

      expect(trip.attention, TripAttention.none);
    });
  });

  group('the booking axis is read from the booking row', () {
    /// The row shape is the one `SupabaseTripsDatasource` selects: an
    /// `operation_bookings` row with its trip embedded under `operation_trips`.
    Map<String, dynamic> row({
      required String bookingStatus,
      required String tripStatus,
      String paymentStatus = 'pending',
    }) => {
      'id': 'b1',
      'status': bookingStatus,
      'payment_status': paymentStatus,
      'route': 'Banha → Smart Village',
      'payment_amount': 50,
      'seat': 'A1',
      'operation_trips': {'id': 't1', 'status': tripStatus},
    };

    test('reserved stays reserved even on an open trip', () {
      final trip = TripMapper.fromBookingRow(
        row(bookingStatus: 'reserved', tripStatus: 'open_for_booking'),
      ).toEntity();

      expect(trip.bookingState, BookingState.reserved);
      expect(trip.status, TripStatus.upcoming);
      expect(trip.attention, TripAttention.paymentIncomplete);
    });

    test('confirmed + approved is a settled booking', () {
      final trip = TripMapper.fromBookingRow(
        row(
          bookingStatus: 'confirmed',
          tripStatus: 'open_for_booking',
          paymentStatus: 'approved',
        ),
      ).toEntity();

      expect(trip.bookingState, BookingState.confirmed);
      expect(trip.attention, TripAttention.none);
    });

    test('boarded is a confirmed seat, not a finished journey', () {
      // The Dashboard's vocabulary has `boarded`; whether the journey is over is
      // the trip's axis to answer, not the booking's.
      final trip = TripMapper.fromBookingRow(
        row(
          bookingStatus: 'boarded',
          tripStatus: 'in_progress',
          paymentStatus: 'approved',
        ),
      ).toEntity();

      expect(trip.bookingState, BookingState.confirmed);
      expect(trip.status, TripStatus.inProgress);
      expect(trip.attention, TripAttention.none);
      expect(trip.canBeTracked, isTrue);
    });

    test('an unrecognised booking status is never treated as confirmed', () {
      final trip = TripMapper.fromBookingRow(
        row(bookingStatus: 'some_future_status', tripStatus: 'scheduled'),
      ).toEntity();

      expect(trip.bookingState, BookingState.reserved);
    });
  });
}
