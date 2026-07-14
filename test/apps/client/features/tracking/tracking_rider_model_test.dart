import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/tracking/data/models/tracking_rider_model.dart';

/// The rider's boarding and drop-off points must land on the right stops. The
/// screen badges those two rows and counts down to them, so a mismatch here
/// tells a passenger to get off at the wrong station.
void main() {
  group('TrackingRiderModel.fromRows', () {
    final points = [
      _point(order: 0, routePointId: 'rp-a', name: 'Banha'),
      _point(order: 1, routePointId: 'rp-b', name: 'Nasr City'),
      _point(order: 2, routePointId: 'rp-c', name: 'Heliopolis'),
      _point(order: 3, routePointId: 'rp-d', name: 'Smart Village'),
    ];

    test('resolves the rider segment by point id', () {
      final rider = TrackingRiderModel.fromRows(
        passengerRow: _passenger(pickupId: 'rp-b', dropoffId: 'rp-d'),
        pointRows: points,
      );

      expect(rider.boardingIndex, 1);
      expect(rider.dropoffIndex, 3);
      expect(rider.seatLabel, '12');
      expect(rider.hasBoarded, isTrue);
    });

    test('falls back to the point name when the id is absent', () {
      final rider = TrackingRiderModel.fromRows(
        passengerRow: _passenger(
          pickupId: null,
          dropoffId: null,
          pickupName: 'Nasr City',
          dropoffName: 'smart village', // case-insensitive
        ),
        pointRows: points,
      );

      expect(rider.boardingIndex, 1);
      expect(rider.dropoffIndex, 3);
    });

    test(
      'prefers the id over a stale name, so a renamed station cannot move '
      'the rider badge onto the wrong stop',
      () {
        final rider = TrackingRiderModel.fromRows(
          // The operator renamed rp-c after the booking was made; the manifest
          // still carries the old name, which now matches a different station.
          passengerRow: _passenger(
            pickupId: 'rp-c',
            dropoffId: 'rp-d',
            pickupName: 'Banha',
          ),
          pointRows: points,
        );

        expect(rider.boardingIndex, 2);
      },
    );

    test('leaves the index null when the point is not on this trip', () {
      final rider = TrackingRiderModel.fromRows(
        passengerRow: _passenger(
          pickupId: 'rp-zzz',
          dropoffId: null,
          pickupName: 'Somewhere else',
        ),
        pointRows: points,
      );

      expect(rider.boardingIndex, isNull);
    });

    test('is empty when the manifest is not readable', () {
      final rider = TrackingRiderModel.fromRows(
        passengerRow: null,
        pointRows: points,
      );

      expect(rider.boardingIndex, isNull);
      expect(rider.hasSeat, isFalse);
      expect(rider.hasBoarded, isFalse);
    });
  });

  group('rider leg', () {
    test('marks only the stops between boarding and drop-off as the leg', () {
      final rider = TrackingRiderModel.fromRows(
        passengerRow: _passenger(pickupId: 'rp-b', dropoffId: 'rp-c'),
        pointRows: [
          _point(order: 0, routePointId: 'rp-a', name: 'Banha'),
          _point(order: 1, routePointId: 'rp-b', name: 'Nasr City'),
          _point(order: 2, routePointId: 'rp-c', name: 'Heliopolis'),
          _point(order: 3, routePointId: 'rp-d', name: 'Smart Village'),
        ],
      );

      expect(rider.isOnRiderLeg(0), isFalse);
      expect(rider.isOnRiderLeg(1), isTrue);
      expect(rider.isOnRiderLeg(2), isTrue);
      expect(rider.isOnRiderLeg(3), isFalse);
    });

    test('treats every stop as on-leg when the segment is unknown', () {
      final rider = TrackingRiderModel.fromRows(
        passengerRow: null,
        pointRows: const [],
      );

      expect(rider.isOnRiderLeg(0), isTrue);
      expect(rider.isOnRiderLeg(5), isTrue);
    });
  });
}

Map<String, dynamic> _point({
  required int order,
  required String routePointId,
  required String name,
}) {
  return {
    'id': 'trp-$order',
    'route_point_id': routePointId,
    'point_name': name,
    'point_order': order,
    'latitude': 30.0 + order,
    'longitude': 31.0,
  };
}

Map<String, dynamic> _passenger({
  String? pickupId,
  String? dropoffId,
  String pickupName = 'Nasr City',
  String dropoffName = 'Smart Village',
}) {
  return {
    'seat_label': '12',
    'pickup_point_id': pickupId,
    'pickup_point_name': pickupName,
    'dropoff_point_id': dropoffId,
    'dropoff_point_name': dropoffName,
    'status': 'confirmed',
  };
}
