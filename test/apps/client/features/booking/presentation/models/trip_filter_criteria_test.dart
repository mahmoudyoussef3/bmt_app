import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/models/trip_filter_criteria.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/day_part.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/trip_sort.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RouteTripOptionData _trip({
  String departureTime = '08:30 AM',
  String arrivalTime = '10:00 AM',
  int availableSeats = 4,
  String vehicleType = 'Van',
  String price = r'$50',
}) {
  return RouteTripOptionData(
    id: 't1',
    departureTime: departureTime,
    arrivalTime: arrivalTime,
    availableSeats: availableSeats,
    vehicleType: vehicleType,
    price: price,
  );
}

void main() {
  group('TripFilterCriteria.parseHour24', () {
    test('parses a 12-hour AM time', () {
      expect(TripFilterCriteria.parseHour24('08:30 AM'), 8);
    });

    test('parses a 12-hour PM time', () {
      expect(TripFilterCriteria.parseHour24('02:15 PM'), 14);
    });

    test('parses a 24-hour time with no AM/PM marker', () {
      expect(TripFilterCriteria.parseHour24('20:30'), 20);
    });

    test('returns null for an unparseable string', () {
      expect(TripFilterCriteria.parseHour24('Not set'), isNull);
    });
  });

  group('TripFilterCriteria.matches', () {
    test('rejects a trip outside the seats range', () {
      const criteria = TripFilterCriteria(seatsRange: RangeValues(5, 10));
      expect(criteria.matches(_trip(availableSeats: 2)), isFalse);
    });

    test('rejects a trip with a non-matching vehicle type', () {
      const criteria = TripFilterCriteria(vehicleType: 'Bus');
      expect(criteria.matches(_trip(vehicleType: 'Van')), isFalse);
    });

    test('rejects a trip outside the selected time-of-day bucket', () {
      const criteria = TripFilterCriteria(timeOfDay: DayPart.evening);
      expect(criteria.matches(_trip(departureTime: '08:30 AM')), isFalse);
    });

    test('does not exclude a trip with an unparseable departure time', () {
      const criteria = TripFilterCriteria(timeOfDay: DayPart.evening);
      expect(criteria.matches(_trip(departureTime: 'Not set')), isTrue);
    });
  });

  group('TripFilterCriteria.compare', () {
    test('earliest sorts ascending by departure hour', () {
      const criteria = TripFilterCriteria(sort: TripSort.earliest);
      final early = _trip(departureTime: '06:00 AM');
      final late = _trip(departureTime: '09:00 PM');
      expect(criteria.compare(early, late), lessThan(0));
    });

    test('seatsHigh sorts descending by available seats', () {
      const criteria = TripFilterCriteria(sort: TripSort.seatsHigh);
      final fewer = _trip(availableSeats: 2);
      final more = _trip(availableSeats: 8);
      expect(criteria.compare(more, fewer), lessThan(0));
    });
  });
}
