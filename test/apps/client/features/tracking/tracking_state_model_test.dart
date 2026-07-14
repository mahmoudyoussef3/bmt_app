import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/tracking/data/models/tracking_state_model.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip_state.dart';

/// The rider's trip state is derived from operational truth only — the trip's
/// status, then the captain's events, then (last) whether a fix exists at all.
void main() {
  group('TrackingStateModel.resolve', () {
    test('the trip status wins when it is decisive', () {
      expect(
        TrackingStateModel.resolve(
          tripStatus: 'in_progress',
          latestEventTitle: null,
          hasLiveLocation: false,
        ),
        TrackingTripState.inProgress,
      );
      expect(
        TrackingStateModel.resolve(
          tripStatus: 'completed',
          // Even a stale "on the way" event cannot reopen a finished trip.
          latestEventTitle: 'السائق في الطريق',
          hasLiveLocation: true,
        ),
        TrackingTripState.completed,
      );
    });

    test('falls back to the captain\'s latest event', () {
      expect(
        TrackingStateModel.resolve(
          tripStatus: 'scheduled',
          latestEventTitle: 'صعود الركاب',
          hasLiveLocation: false,
        ),
        TrackingTripState.boarding,
      );
      expect(
        TrackingStateModel.resolve(
          tripStatus: 'open_for_booking',
          latestEventTitle: 'غادرت الرحلة',
          hasLiveLocation: false,
        ),
        TrackingTripState.inProgress,
      );
    });

    test('a live fix alone means the captain is already moving', () {
      expect(
        TrackingStateModel.resolve(
          tripStatus: 'scheduled',
          latestEventTitle: null,
          hasLiveLocation: true,
        ),
        TrackingTripState.driverOnWay,
      );
    });

    test('a scheduled trip with no signal has simply not started', () {
      expect(
        TrackingStateModel.resolve(
          tripStatus: 'scheduled',
          latestEventTitle: null,
          hasLiveLocation: false,
        ),
        TrackingTripState.notStarted,
      );
    });
  });
}
