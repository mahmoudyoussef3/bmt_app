import 'package:flutter_test/flutter_test.dart';
import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/services/route_schedule_calculator.dart';

void main() {
  group('RouteScheduleCalculator.computeStopOffsets', () {
    test('accumulates travel time and dwell into arrival/departure offsets', () {
      // 3 points (start, stop, end) => 2 legs of 10 min each.
      const legs = [
        RouteLeg(distanceMeters: 5000, durationSeconds: 600), // 10 min
        RouteLeg(distanceMeters: 5000, durationSeconds: 600), // 10 min
      ];
      // dwell: start 0, middle 5, end 0
      final schedule = RouteScheduleCalculator.computeStopOffsets(
        legs: legs,
        dwellMinutes: const [0, 5, 0],
      );

      expect(schedule.length, 3);
      // Start: no travel yet, dwell 0.
      expect(schedule[0].arrivalOffset, '00:00');
      expect(schedule[0].departureOffset, '00:00');
      // Middle: 10 min travel, then 5 min dwell.
      expect(schedule[1].arrivalOffset, '00:10');
      expect(schedule[1].departureOffset, '00:15');
      // End: 10 (leg0) + 5 (dwell) + 10 (leg1) = 25 min.
      expect(schedule[2].arrivalOffset, '00:25');
      expect(schedule[2].departureOffset, '00:25');
    });

    test('rolls minutes into hours past 60', () {
      const legs = [
        RouteLeg(distanceMeters: 0, durationSeconds: 3600), // 60 min
        RouteLeg(distanceMeters: 0, durationSeconds: 1800), // 30 min
      ];
      final schedule = RouteScheduleCalculator.computeStopOffsets(
        legs: legs,
        dwellMinutes: const [0, 10, 0],
      );
      expect(schedule[1].arrivalOffset, '01:00');
      expect(schedule[1].departureOffset, '01:10');
      expect(schedule[2].arrivalOffset, '01:40'); // 60 + 10 + 30
    });
  });

  group('formatting', () {
    test('formatDistance shows one decimal under 10km, none above', () {
      expect(RouteScheduleCalculator.formatDistance(8400), '8.4 كم');
      expect(RouteScheduleCalculator.formatDistance(42000), '42 كم');
    });

    test('formatDuration shows hours and minutes', () {
      expect(RouteScheduleCalculator.formatDuration(4200), '1 س 10 د');
      expect(RouteScheduleCalculator.formatDuration(2700), '45 د');
    });
  });
}
