import 'package_plan.dart';

/// One seller as the package filter presents it: just enough identity to show a
/// row in the office picker and to route to the seller's marketplace profile.
///
/// Derived from the catalogue itself, so only offices that actually have
/// packages ever appear as a filter option.
class PackageOffice {
  const PackageOffice({
    required this.id,
    required this.name,
    this.logoUrl,
    this.rating = 0,
    this.ratingsCount = 0,
    this.packageCount = 0,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final double rating;
  final int ratingsCount;

  /// How many packages this office contributes to the catalogue.
  final int packageCount;

  bool get hasRating => ratingsCount > 0 && rating > 0;

  PackageOffice _withOneMore() => PackageOffice(
    id: id,
    name: name,
    logoUrl: logoUrl,
    rating: rating,
    ratingsCount: ratingsCount,
    packageCount: packageCount + 1,
  );

  /// The distinct sellers across [packages], best-rated first then
  /// alphabetically — the same order the office directory uses, so the picker
  /// stays stable and familiar. Office-less packages are ignored.
  static List<PackageOffice> from(List<PackagePlan> packages) {
    final byId = <String, PackageOffice>{};
    for (final package in packages) {
      if (!package.hasOffice) continue;
      final existing = byId[package.officeId];
      byId[package.officeId] = existing == null
          ? PackageOffice(
              id: package.officeId,
              name: package.officeName,
              logoUrl: package.officeLogoUrl,
              rating: package.officeRating,
              ratingsCount: package.officeRatingsCount,
              packageCount: 1,
            )
          : existing._withOneMore();
    }

    final offices = byId.values.toList();
    offices.sort((a, b) {
      final byRating = b.rating.compareTo(a.rating);
      if (byRating != 0) return byRating;
      return a.name.compareTo(b.name);
    });
    return offices;
  }
}
