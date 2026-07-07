/// Shared helpers for building filter sheets from a list of numeric/text
/// fields — used by both the routes discovery filter sheet and Route
/// Details' available-trips filter sheet so this logic isn't duplicated
/// per screen (`CLAUDE.md` core-before-utility rule).
library;

/// The (min, max) span of the non-null values, padded by 1 if they would
/// otherwise collide — a [RangeSlider] requires `min < max`.
(double, double) numericBounds(Iterable<int?> values) {
  final nums = values.whereType<int>();
  if (nums.isEmpty) return (0, 1);
  final min = nums.reduce((a, b) => a < b ? a : b).toDouble();
  final max = nums.reduce((a, b) => a > b ? a : b).toDouble();
  return max > min ? (min, max) : (min, min + 1);
}

/// Non-empty, deduplicated, alphabetically sorted values.
List<String> uniqueSortedValues(Iterable<String> values) {
  return values.where((v) => v.trim().isNotEmpty).toSet().toList()..sort();
}
