/// Arabic counted nouns for the captain app.
///
/// Dropping a number in front of a noun is an English habit that reads as
/// broken Arabic: "1 محطة"، "2 محطة". Arabic marks one and two in the noun
/// itself, takes the plural for three to ten, and returns to the singular past
/// that. The count and its word cannot be assembled separately at the call
/// site, so they are chosen together here — and here rather than inside a
/// feature, because the same nouns are counted on the day list and in the
/// history tab, and the two must not drift apart.
class CaptainCounts {
  const CaptainCounts._();

  /// A route's stations, e.g. `محطتان`، `5 محطات`.
  static String stops(int count) => switch (count) {
    1 => 'محطة واحدة',
    2 => 'محطتان',
    <= 10 => '$count محطات',
    _ => '$count محطة',
  };

  /// Seats sold on a trip, e.g. `راكبان`، `18 راكبًا`.
  static String passengers(int count) => switch (count) {
    0 => 'لا ركاب',
    1 => 'راكب واحد',
    2 => 'راكبان',
    <= 10 => '$count ركاب',
    _ => '$count راكبًا',
  };
}
