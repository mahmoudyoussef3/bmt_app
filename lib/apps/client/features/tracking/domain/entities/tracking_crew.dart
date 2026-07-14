/// The captain driving this trip, with their real service rating.
///
/// [rating] and [ratingCount] come from `drivers.rating` / `drivers.rating_count`,
/// which the `trip_reviews` triggers keep up to date. A driver nobody has rated
/// yet has no rating — the UI says so rather than inventing one.
class TrackingCaptain {
  const TrackingCaptain({
    this.name,
    this.phone,
    this.rating,
    this.ratingCount = 0,
  });

  final String? name;
  final String? phone;
  final double? rating;
  final int ratingCount;

  bool get hasRating => ratingCount > 0 && rating != null && rating! > 0;

  bool get isCallable => phone != null && phone!.trim().isNotEmpty;

  String? get displayName {
    final value = name?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  /// Up to two initials for the avatar; null when we don't know the name, so
  /// the UI can fall back to an icon instead of inventing a "DR" placeholder.
  String? get initials {
    final value = displayName;
    if (value == null) return null;
    final parts = value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2);
    if (parts.isEmpty) return null;
    return parts.map((part) => part[0]).join().toUpperCase();
  }
}

/// The vehicle running this trip, with its real service rating
/// (`vehicles.rating` / `vehicles.rating_count`).
class TrackingVehicle {
  const TrackingVehicle({
    this.brand,
    this.model,
    this.type,
    this.plate,
    this.rating,
    this.ratingCount = 0,
  });

  final String? brand;
  final String? model;
  final String? type;
  final String? plate;
  final double? rating;
  final int ratingCount;

  bool get hasRating => ratingCount > 0 && rating != null && rating! > 0;

  /// "Toyota Hiace", "Hiace", or null — whatever the fleet record actually has.
  String? get displayName {
    final parts = [
      brand,
      model,
    ].map((p) => p?.trim()).where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' ');
  }

  String? get displayPlate {
    final value = plate?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
