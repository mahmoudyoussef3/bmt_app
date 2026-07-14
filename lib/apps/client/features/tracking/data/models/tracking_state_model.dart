import '../../domain/entities/tracking_trip_state.dart';

/// Derives the rider-facing trip state from operational truth: the trip's own
/// status first, then the captain's latest reported event, then — only as a
/// last resort — the existence of a live GPS fix.
///
/// Nothing in the presentation layer may set this. The screen shows where the
/// trip actually is, not where anyone wishes it were.
abstract final class TrackingStateModel {
  static TrackingTripState resolve({
    required String? tripStatus,
    required String? latestEventTitle,
    required bool hasLiveLocation,
  }) {
    return switch (tripStatus) {
      'in_progress' => TrackingTripState.inProgress,
      'boarding' => TrackingTripState.boarding,
      'completed' => TrackingTripState.completed,
      _ => _fromEvent(latestEventTitle, hasLiveLocation: hasLiveLocation),
    };
  }

  /// The captain's app writes these exact titles into `trip_events`; the
  /// dashboard reads the same strings. Keep them in sync with both.
  static TrackingTripState _fromEvent(
    String? title, {
    required bool hasLiveLocation,
  }) {
    return switch (title) {
      'اكتملت الرحلة' || 'وصلت الرحلة للوجهة' => TrackingTripState.completed,
      'غادرت الرحلة' => TrackingTripState.inProgress,
      'صعود الركاب' ||
      'وصل السائق لنقطة الانطلاق' => TrackingTripState.boarding,
      'السائق في الطريق' => TrackingTripState.driverOnWay,
      _ => hasLiveLocation
          ? TrackingTripState.driverOnWay
          : TrackingTripState.notStarted,
    };
  }
}
