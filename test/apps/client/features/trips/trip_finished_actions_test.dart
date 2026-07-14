import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';

TripData _trip({
  required TripStatus status,
  PaymentStatus paymentStatus = PaymentStatus.paid,
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

    test('an unfinished trip cannot be rated, rated or not', () {
      expect(_trip(status: TripStatus.upcoming).canBeReviewed, isFalse);
      expect(_trip(status: TripStatus.inProgress).canBeReviewed, isFalse);
      expect(_trip(status: TripStatus.cancelled).canBeReviewed, isFalse);
    });
  });
}
