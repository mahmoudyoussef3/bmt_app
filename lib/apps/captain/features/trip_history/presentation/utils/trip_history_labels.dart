import 'package:bmt_app/apps/captain/core/utils/captain_counts.dart';

/// Arabic counts for the history tab.
///
/// Dropping a number in front of a noun is an English habit that reads as
/// broken Arabic: "1 رحلة"، "2 رحلة". Arabic marks one and two in the noun
/// itself, takes the plural for three to ten, and returns to the singular past
/// that — and any adjective has to agree with whichever form was chosen. The
/// count and its words can't be assembled separately at the call site, so they
/// are chosen together here.
class TripHistoryLabels {
  const TripHistoryLabels._();

  /// The history header's subtitle, e.g. `رحلتان مكتملتان`، `24 رحلة مكتملة`.
  static String completedTrips(int count) => switch (count) {
    0 => 'لا رحلات مكتملة',
    1 => 'رحلة واحدة مكتملة',
    2 => 'رحلتان مكتملتان',
    <= 10 => '$count رحلات مكتملة',
    _ => '$count رحلة مكتملة',
  };

  /// What the active filters left behind, e.g. `نتيجتان`، `7 نتائج`.
  static String results(int count) => switch (count) {
    0 => 'لا نتائج',
    1 => 'نتيجة واحدة',
    2 => 'نتيجتان',
    <= 10 => '$count نتائج',
    _ => '$count نتيجة',
  };

  /// A trip's boarding line, e.g. `صعد 18 راكبًا من أصل 20`.
  static String boarded(int boarded, int total) {
    return switch (boarded) {
      0 => 'لم يصعد أي راكب من أصل $total',
      1 => 'صعد راكب واحد من أصل $total',
      2 => 'صعد راكبان من أصل $total',
      <= 10 => 'صعد $boarded ركاب من أصل $total',
      _ => 'صعد $boarded راكبًا من أصل $total',
    };
  }

  /// The seats a trip sold and never boarded, e.g. `لم يصعد راكبان`.
  ///
  /// Stated outright rather than left as `20 − 18`: the shortfall is the whole
  /// reason a captain looks twice at a finished trip, and making them subtract
  /// two numbers to find it is the card withholding its own point.
  static String notBoarded(int count) => switch (count) {
    1 => 'لم يصعد راكب واحد',
    2 => 'لم يصعد راكبان',
    <= 10 => 'لم يصعد $count ركاب',
    _ => 'لم يصعد $count راكبًا',
  };

  /// How the trip ended, in one sentence.
  ///
  /// The detail page could state the booked count, the boarded count and a
  /// progress bar and still leave the captain to work out whether the trip went
  /// well. This is the conclusion those figures add up to.
  static String outcome({required int boarded, required int total}) {
    if (total == 0) return 'اكتملت الرحلة دون ركاب مسجلين';
    final missing = total - boarded;
    if (missing <= 0) return 'اكتملت الرحلة وصعد جميع الركاب';
    return 'اكتملت الرحلة — ${notBoarded(missing)}';
  }

  /// The stations section's count, e.g. `5 محطات`.
  ///
  /// Delegated so the history tab and the day list count the same noun the same
  /// way — the assigned-trip card states a route's stop count too.
  static String stops(int count) => CaptainCounts.stops(count);
}
