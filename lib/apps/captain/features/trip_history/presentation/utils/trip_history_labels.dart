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

  /// The stations section's count, e.g. `5 محطات`.
  static String stops(int count) => switch (count) {
    1 => 'محطة واحدة',
    2 => 'محطتان',
    <= 10 => '$count محطات',
    _ => '$count محطة',
  };
}
