import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/home/data/models/home_booking_model.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';

Map<String, dynamic> _row({
  String status = 'reserved',
  String? pickupPoint = 'El-Marg',
  String? dropoffPoint = 'AUC',
  String route = 'El-Marg → AUC',
  num? amount = 100,
}) {
  // Mirrors the columns `operation_bookings` actually has. The table stores one
  // seat per booking — there is no seats_count — so nothing here may invent one.
  return {
    'id': 'b1',
    'trip_id': 't1',
    'booking_number': 'BK-1A2B3C4D',
    'status': status,
    'seat': 'A3',
    'trip_date': '2026-07-20',
    'trip_time': '08:30:00',
    'route': route,
    'payment_amount': amount,
    'pickup_point_name': pickupPoint,
    'dropoff_point_name': dropoffPoint,
  };
}

void main() {
  group('HomeBookingMapper', () {
    // Regression: Home used to query bookings by the retired `newRequest /
    // approved / active` vocabulary, so a booking awaiting payment review —
    // which Supabase stores as `reserved` — matched nothing and vanished from
    // Home entirely. The rider saw the trip sitting in the departures feed as
    // though they had never booked it.
    test('a booking awaiting payment review surfaces as under review', () {
      final booking = HomeBookingMapper.fromRow(_row(status: 'reserved'));

      expect(booking, isNotNull);
      expect(booking!.status, HomeBookingStatus.underReview);
      expect(booking.status.isTrackable, isFalse);
      expect(booking.tripId, 't1');
      expect(booking.bookingNumber, 'BK-1A2B3C4D');
    });

    test('the live statuses Home queries match the mapped ones', () {
      for (final status in HomeBookingStatus.liveStatuses) {
        expect(
          HomeBookingMapper.fromRow(_row(status: status)),
          isNotNull,
          reason: '$status is queried, so it must map to a shown status',
        );
      }
    });

    test('an approved booking is confirmed and trackable', () {
      final booking = HomeBookingMapper.fromRow(_row(status: 'confirmed'))!;

      expect(booking.status, HomeBookingStatus.confirmed);
      expect(booking.status.isTrackable, isTrue);
    });

    test('a boarded booking reads as on board', () {
      final booking = HomeBookingMapper.fromRow(_row(status: 'boarded'))!;

      expect(booking.status, HomeBookingStatus.onBoard);
    });

    test('bookings that are no longer live are not shown', () {
      for (final status in const ['draft', 'completed', 'cancelled', '']) {
        expect(
          HomeBookingMapper.fromRow(_row(status: status)),
          isNull,
          reason: '$status is not a seat the rider still holds',
        );
      }
    });

    test('falls back to the route label when point names are missing', () {
      final booking = HomeBookingMapper.fromRow(
        _row(pickupPoint: null, dropoffPoint: '  '),
      )!;

      expect(booking.pickup, 'El-Marg');
      expect(booking.destination, 'AUC');
    });

    test('an unpriced booking carries no fare rather than a fake zero', () {
      expect(HomeBookingMapper.fromRow(_row(amount: 0))!.fare, isEmpty);
      expect(HomeBookingMapper.fromRow(_row(amount: null))!.fare, isEmpty);
      expect(HomeBookingMapper.fromRow(_row())!.fare, 'EGP 100');
    });
  });
}
