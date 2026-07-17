import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/trip_history/presentation/utils/trip_history_labels.dart';

/// The forms these assert are Arabic grammar, not copy preferences: a count
/// glued to a fixed noun ("1 رحلة", "2 رحلة") is wrong in a way an Arabic
/// speaker reads instantly, and it is exactly what creeps back in the moment
/// someone interpolates a number at a call site.
void main() {
  group('completedTrips', () {
    test('one and two are marked in the noun, not by the digit', () {
      expect(TripHistoryLabels.completedTrips(1), 'رحلة واحدة مكتملة');
      expect(TripHistoryLabels.completedTrips(2), 'رحلتان مكتملتان');
    });

    test('three to ten take the plural', () {
      expect(TripHistoryLabels.completedTrips(3), '3 رحلات مكتملة');
      expect(TripHistoryLabels.completedTrips(10), '10 رحلات مكتملة');
    });

    test('past ten returns to the singular', () {
      expect(TripHistoryLabels.completedTrips(11), '11 رحلة مكتملة');
      expect(TripHistoryLabels.completedTrips(24), '24 رحلة مكتملة');
    });

    test('none says so in words rather than showing a zero', () {
      expect(TripHistoryLabels.completedTrips(0), 'لا رحلات مكتملة');
    });
  });

  group('results', () {
    test('covers each Arabic count form', () {
      expect(TripHistoryLabels.results(0), 'لا نتائج');
      expect(TripHistoryLabels.results(1), 'نتيجة واحدة');
      expect(TripHistoryLabels.results(2), 'نتيجتان');
      expect(TripHistoryLabels.results(7), '7 نتائج');
      expect(TripHistoryLabels.results(30), '30 نتيجة');
    });
  });

  group('boarded', () {
    test('reads as a sentence at every count', () {
      expect(TripHistoryLabels.boarded(0, 20), 'لم يصعد أي راكب من أصل 20');
      expect(TripHistoryLabels.boarded(1, 20), 'صعد راكب واحد من أصل 20');
      expect(TripHistoryLabels.boarded(2, 20), 'صعد راكبان من أصل 20');
      expect(TripHistoryLabels.boarded(5, 20), 'صعد 5 ركاب من أصل 20');
      expect(TripHistoryLabels.boarded(18, 20), 'صعد 18 راكبًا من أصل 20');
    });
  });

  group('stops', () {
    test('covers each Arabic count form', () {
      expect(TripHistoryLabels.stops(1), 'محطة واحدة');
      expect(TripHistoryLabels.stops(2), 'محطتان');
      expect(TripHistoryLabels.stops(5), '5 محطات');
      expect(TripHistoryLabels.stops(12), '12 محطة');
    });
  });
}
