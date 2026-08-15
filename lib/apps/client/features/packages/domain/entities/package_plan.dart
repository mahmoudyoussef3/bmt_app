/// A commute package a rider can subscribe to, as published by the Dashboard.
class PackagePlan {
  const PackagePlan({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.packageType,
    required this.durationDays,
    required this.rideCount,
    required this.price,
    this.descriptionAr = '',
    this.descriptionEn = '',
    this.officeId = '',
    this.officeName = '',
    this.officeLogoUrl,
    this.officeRating = 0,
    this.officeRatingsCount = 0,
    this.officeDescription = '',
    this.officeServiceAreas = const [],
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String packageType;
  final int durationDays;
  final int rideCount;

  /// The office's own description of this package, bilingual. Empty when
  /// the office hasn't written one yet.
  final String descriptionAr;
  final String descriptionEn;

  /// The catalogue's flat price, kept only as the booking wizard's fallback
  /// when a corridor has no dedicated package tier (see
  /// `BookingWizardSession.resolvedPackagePrice`). It is never shown while
  /// browsing: the same plan is priced per pickup→dropoff pair, so this figure
  /// is not what most riders would actually pay.
  final double price;

  /// The office selling this package. Packages are per-office (offices compete
  /// on price), so a mixed catalogue must say whose offer each card is, and let
  /// a rider open the seller's marketplace profile from the package itself.
  final String officeId;
  final String officeName;
  final String? officeLogoUrl;

  /// The seller's explicit passenger rating, straight off `public_offices` — the
  /// same figure the office directory shows, never inferred from another score.
  final double officeRating;
  final int officeRatingsCount;

  /// The seller's marketplace blurb and service areas, also straight off
  /// `public_offices` — lets the office profile opened from this package
  /// render as fully as one opened from the Offices Directory.
  final String officeDescription;
  final List<String> officeServiceAreas;

  /// Whether this package carries enough office identity to render the provider
  /// badge and route to the office profile. A package whose office is unlisted
  /// arrives office-less and is filtered out before it reaches the catalogue.
  bool get hasOffice => officeId.isNotEmpty && officeName.isNotEmpty;

  /// True once the seller has at least one passenger rating; guards showing a
  /// misleading 0.0 for a brand-new office.
  bool get hasOfficeRating => officeRatingsCount > 0 && officeRating > 0;

  /// The name to show riders: English when the Dashboard has set one, and the
  /// Arabic name otherwise — never a blank plan on a checkout screen.
  String get displayName => nameEn.trim().isEmpty ? nameAr : nameEn;

  /// The description to show riders, same EN-falls-back-to-AR rule as
  /// [displayName]. Empty when the office hasn't written either.
  String get displayDescription =>
      descriptionEn.trim().isEmpty ? descriptionAr : descriptionEn;
}
