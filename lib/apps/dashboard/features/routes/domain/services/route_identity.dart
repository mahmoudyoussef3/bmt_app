/// Naming helpers for the route builder.
///
/// The old form asked the operator to type a route name *and* a route code by
/// hand before anything else could be done. Production data shows what that
/// produced: codes like `new 1`, `200`, `jwfoiklq`, and names that repeat the
/// raw geocoder label ("El-Marg, QH, Egypt"). Both are now derived from the two
/// places the operator actually picks, and stay editable.
class RouteIdentity {
  const RouteIdentity._();

  /// The human part of a geocoder label: `"El-Marg, QH, Egypt"` → `"El-Marg"`.
  ///
  /// Geocoders append administrative area and country to every result; carrying
  /// that into a route name, a stop title or a `start_city` column makes every
  /// screen that shows them unreadable.
  static String shortPlaceLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final head = trimmed.split(',').first.trim();
    return head.isEmpty ? trimmed : head;
  }

  /// The administrative area of a geocoder label — the segment before the
  /// country, e.g. `"El-Marg, QH, Egypt"` → `"QH"`. Falls back to the short
  /// label when the result has no area segment.
  static String areaFromLabel(String raw) {
    final parts = raw
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) return parts[parts.length - 2];
    return shortPlaceLabel(raw);
  }

  /// `"بنها - القرية الذكية"`, matching the naming already in the routes table.
  /// Returns an empty string until both endpoints are known, so the builder can
  /// tell "not named yet" from "named".
  static String suggestName(String origin, String destination) {
    final from = shortPlaceLabel(origin);
    final to = shortPlaceLabel(destination);
    if (from.isEmpty || to.isEmpty) return '';
    return '$from - $to';
  }

  /// The first free `RT-nn` code. Sequential and unique within the office, so
  /// the operator never has to invent one — and never collides with an existing
  /// route by accident.
  static String suggestCode(Iterable<String> existingCodes) {
    final used = <int>{};
    final pattern = RegExp(r'^RT-(\d+)$', caseSensitive: false);
    for (final code in existingCodes) {
      final match = pattern.firstMatch(code.trim());
      if (match != null) used.add(int.parse(match.group(1)!));
    }
    var next = 1;
    while (used.contains(next)) {
      next++;
    }
    return 'RT-${next.toString().padLeft(2, '0')}';
  }
}
