import '../../domain/entities/office_summary.dart';

/// Wire shape of a `public_offices` row. Defensive throughout — the view is
/// public and a half-filled office profile must not crash the directory.
class OfficeSummaryModel extends OfficeSummary {
  const OfficeSummaryModel({
    required super.id,
    required super.name,
    super.logoUrl,
    super.description,
    super.rating,
    super.ratingsCount,
    super.serviceAreas,
    super.routesCount,
  });

  factory OfficeSummaryModel.fromJson(Map<String, dynamic> json) {
    return OfficeSummaryModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      logoUrl: json['logo_url'] as String?,
      description: (json['description'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingsCount: (json['ratings_count'] as num?)?.toInt() ?? 0,
      serviceAreas:
          (json['service_areas'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      routesCount: (json['routes_count'] as num?)?.toInt() ?? 0,
    );
  }
}
