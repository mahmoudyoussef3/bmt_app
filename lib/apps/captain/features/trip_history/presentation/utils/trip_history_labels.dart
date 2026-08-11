import 'package:bmt_app/apps/captain/core/utils/captain_counts.dart';

class TripHistoryLabels {
  const TripHistoryLabels._();

  static String completedTrips(int count) => switch (count) {
    0 => 'لا رحلات مكتملة',
    1 => 'رحلة واحدة مكتملة',
    2 => 'رحلتان مكتملتان',
    <= 10 => '$count رحلات مكتملة',
    _ => '$count رحلة مكتملة',
  };

  static String results(int count) => switch (count) {
    0 => 'لا نتائج',
    1 => 'نتيجة واحدة',
    2 => 'نتيجتان',
    <= 10 => '$count نتائج',
    _ => '$count نتيجة',
  };

  static String boarded(int boarded, int total) {
    return switch (boarded) {
      0 => 'لم يصعد أي راكب من أصل $total',
      1 => 'صعد راكب واحد من أصل $total',
      2 => 'صعد راكبان من أصل $total',
      <= 10 => 'صعد $boarded ركاب من أصل $total',
      _ => 'صعد $boarded راكبًا من أصل $total',
    };
  }

  static String stops(int count) => CaptainCounts.stops(count);
}
