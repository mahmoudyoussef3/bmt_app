import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_seat.dart';

TripData _trip({
  List<TripSeat> seatMap = const [],
  List<String> seats = const [],
}) {
  return TripData(
    id: 'b1',
    reference: 'BMT-TEST',
    status: TripStatus.upcoming,
    pickup: 'A',
    destination: 'B',
    dateLabel: 'Today',
    timeLabel: '08:00',
    driverName: 'Sam',
    driverPhone: '',
    driverInitials: 'SA',
    driverRating: 4.8,
    vehicleName: 'Coaster',
    vehicleType: 'Minibus',
    vehicleId: 'v1',
    seats: seats,
    paymentStatus: PaymentStatus.paid,
    fare: 'EGP 50',
    seatMap: seatMap,
  );
}

TripSeat _seat(String label, TripSeatState state, {int row = 0, int col = 0}) {
  return TripSeat(
    label: label,
    number: int.tryParse(label) ?? 0,
    row: row,
    column: col,
    state: state,
  );
}

void main() {
  group('TripData seat helpers', () {
    test('derives capacity and availability from the live seat map', () {
      final trip = _trip(
        seatMap: [
          _seat('1', TripSeatState.available),
          _seat('2', TripSeatState.mine),
          _seat('3', TripSeatState.occupied),
          _seat('4', TripSeatState.available),
        ],
      );

      expect(trip.hasSeatMap, isTrue);
      expect(trip.vehicleCapacity, 4);
      expect(trip.availableSeatCount, 2);
    });

    test('prefers the flagged seat from the map for the passenger label', () {
      final trip = _trip(
        seats: const ['booking-fallback'],
        seatMap: [
          _seat('9', TripSeatState.occupied),
          _seat('10', TripSeatState.mine),
        ],
      );

      expect(trip.mySeatLabels, ['10']);
    });

    test('falls back to booking seats when no map seat is flagged mine', () {
      final trip = _trip(
        seats: const ['7'],
        seatMap: [_seat('7', TripSeatState.occupied)],
      );

      expect(trip.mySeatLabels, ['7']);
    });

    test('empty map yields no capacity and an empty passenger label', () {
      final trip = _trip();

      expect(trip.hasSeatMap, isFalse);
      expect(trip.vehicleCapacity, 0);
      expect(trip.availableSeatCount, 0);
      expect(trip.mySeatLabels, isEmpty);
    });
  });

  group('TripSeat', () {
    test('displayLabel falls back to number when label is blank', () {
      const seat = TripSeat(
        label: '  ',
        number: 12,
        row: 1,
        column: 2,
        state: TripSeatState.available,
      );

      expect(seat.displayLabel, '12');
      expect(seat.isAvailable, isTrue);
      expect(seat.isMine, isFalse);
    });
  });
}
