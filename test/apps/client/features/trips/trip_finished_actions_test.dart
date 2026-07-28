import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';

/// A booking that travelled: paid, confirmed, on a real trip.
///
/// [bookingState] defaults to `confirmed` rather than to the entity's own
/// `reserved` default because these cases describe journeys that happened. A
/// `reserved` booking is a seat that was only ever held — it puts nobody on the
/// vehicle, so it must not offer to be rated or tracked, which is asserted
/// separately below.
TripData _trip({
  required TripStatus status,
  PaymentStatus paymentStatus = PaymentStatus.paid,
  BookingState bookingState = BookingState.confirmed,
  bool isReviewed = false,
}) {
  return TripData(
    id: 'booking-1',
    reference: 'BMT-TEST',
    status: status,
    pickup: 'Banha',
    destination: 'Smart Village',
    dateLabel: '2026-07-14',
    timeLabel: '08:00',
    driverName: 'Ahmed',
    driverPhone: '0100',
    driverInitials: 'AM',
    driverRating: 4.5,
    vehicleName: 'Coaster',
    vehicleType: 'Minibus',
    vehicleId: 'v1',
    seats: const ['A1'],
    paymentStatus: paymentStatus,
    bookingState: bookingState,
    fare: 'EGP 50',
    isReviewed: isReviewed,
  );
}

void main() {
  group('a finished trip is a record, not a journey', () {
    test('calling or chatting with the captain stops once the trip ends', () {
      expect(_trip(status: TripStatus.upcoming).canContactDriver, isTrue);
      expect(_trip(status: TripStatus.inProgress).canContactDriver, isTrue);
      expect(_trip(status: TripStatus.completed).canContactDriver, isFalse);
      expect(_trip(status: TripStatus.cancelled).canContactDriver, isFalse);
    });

    test('a completed or cancelled trip can never be tracked', () {
      expect(_trip(status: TripStatus.completed).canBeTracked, isFalse);
      expect(_trip(status: TripStatus.cancelled).canBeTracked, isFalse);
    });

    test('tracking needs a trip under way whose own payment is approved', () {
      expect(_trip(status: TripStatus.upcoming).canBeTracked, isFalse);
      expect(
        _trip(
          status: TripStatus.inProgress,
          paymentStatus: PaymentStatus.underReview,
        ).canBeTracked,
        isFalse,
      );
      expect(_trip(status: TripStatus.inProgress).canBeTracked, isTrue);
    });
  });

  group('rating is offered once', () {
    test('a completed trip the passenger has not rated can be rated', () {
      expect(_trip(status: TripStatus.completed).canBeReviewed, isTrue);
    });

    test('a completed trip that was already rated is never asked again', () {
      expect(
        _trip(status: TripStatus.completed, isReviewed: true).canBeReviewed,
        isFalse,
      );
    });

    test('a seat that was only ever held is not a journey to rate', () {
      // The operator can complete a trip while this rider's booking never left
      // `reserved` — they did not travel on it, so they are not asked to say how
      // it went.
      expect(
        _trip(
          status: TripStatus.completed,
          bookingState: BookingState.reserved,
          paymentStatus: PaymentStatus.underReview,
        ).canBeReviewed,
        isFalse,
      );
    });

    test('an unfinished trip cannot be rated, rated or not', () {
      expect(_trip(status: TripStatus.upcoming).canBeReviewed, isFalse);
      expect(_trip(status: TripStatus.inProgress).canBeReviewed, isFalse);
      expect(_trip(status: TripStatus.cancelled).canBeReviewed, isFalse);
    });
  });
}
