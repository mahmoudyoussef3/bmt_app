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

  /// The shortfall, said as a sentence rather than left as the gap between two
  /// numbers on the same line.
  ///
  /// "18 / 20" makes the captain do the subtraction; "لم يصعد راكبان" is the
  /// fact they were looking for.
  static String notBoarded(int count) => switch (count) {
    <= 0 => '',
    1 => 'لم يصعد راكب واحد',
    2 => 'لم يصعد راكبان',
    <= 10 => 'لم يصعد $count ركاب',
    _ => 'لم يصعد $count راكبًا',
  };

  /// How the finished trip turned out, in one line.
  static String outcome(int boarded, int total) {
    if (total == 0) return 'اكتملت الرحلة بدون ركاب مسجلين';
    final missing = total - boarded;
    if (missing <= 0) return 'اكتملت الرحلة وصعد جميع الركاب';
    return 'اكتملت الرحلة — ${notBoarded(missing)}';
  }

  static String stops(int count) => CaptainCounts.stops(count);
}
