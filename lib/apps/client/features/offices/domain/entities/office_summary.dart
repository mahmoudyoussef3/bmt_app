/// A transportation office as the marketplace presents it.
///
/// Built exclusively from the anon-safe `public_offices` view: name, blurb and
/// the explicit passenger rating. Nothing operational — staff, join codes,
/// payment config — exists on that surface, so it cannot leak through here.
class OfficeSummary {
  const OfficeSummary({
    required this.id,
    required this.name,
    this.logoUrl,
    this.description = '',
    this.rating = 0,
    this.ratingsCount = 0,
    this.serviceAreas = const [],
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String description;

  /// Rated explicitly by passengers on completed trips (`office_rating` in
  /// reviews) — never inferred from driver or vehicle scores.
  final double rating;
  final int ratingsCount;
  final List<String> serviceAreas;

  bool get hasRating => ratingsCount > 0 && rating > 0;

  /// Route-argument resolution, matching the app's `fromArguments` convention.
  static OfficeSummary? fromArguments(Object? args) =>
      args is OfficeSummary ? args : null;
}
