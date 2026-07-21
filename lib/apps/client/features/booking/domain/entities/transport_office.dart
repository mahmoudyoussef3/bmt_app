/// The transport office that operates a route or trip.
///
/// EWT is a marketplace: two offices may run the same New Cairo → Obour corridor at
/// different times and prices, so every route and trip the client shows must say who
/// is behind it. Without this the passenger cannot tell providers apart, and results
/// from different offices would read as one operator's timetable.
///
/// Only intentionally public fields live here. Nothing internal to an office —
/// contact details, staff, fleet documents — reaches the client.
class TransportOffice {
  const TransportOffice({
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

  /// Rated explicitly by passengers on completed trips — never averaged from the
  /// driver or vehicle scores, which measure different things.
  final double rating;
  final int ratingsCount;
  final List<String> serviceAreas;

  bool get hasRating => ratingsCount > 0 && rating > 0;

  /// A placeholder for rows that predate office attribution, so the UI can degrade
  /// to "unknown operator" instead of crashing on a null.
  static const TransportOffice unknown = TransportOffice(id: '', name: '');

  bool get isKnown => id.isNotEmpty;

  factory TransportOffice.fromJson(Map<String, dynamic> json) {
    return TransportOffice(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      logoUrl: json['logo_url'] as String?,
      description: (json['description'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingsCount: (json['ratings_count'] as num?)?.toInt() ?? 0,
      serviceAreas:
          (json['service_areas'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}
