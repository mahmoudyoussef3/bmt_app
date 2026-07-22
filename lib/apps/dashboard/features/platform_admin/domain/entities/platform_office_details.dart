import 'platform_office.dart';

/// One office, as fully as the platform is entitled to see it.
///
/// Wraps the [PlatformOffice] from the list rather than restating its fields, so
/// there is one definition of "is this office listed" and one of "what is missing
/// from its card" — the details screen and the list card cannot disagree.
///
/// What is absent is deliberate and enforced server-side by
/// `platform_office_details`: no operator emails or passwords, no join code, no
/// captain phone numbers, no client PII, no payment credentials, and no booking
/// rows. [counts] carries magnitudes; the contents behind them belong to the
/// office's own dashboard, which is scoped by RLS.
class PlatformOfficeDetails {
  const PlatformOfficeDetails({
    required this.office,
    required this.counts,
    required this.operators,
    this.marketplace,
  });

  final PlatformOffice office;
  final PlatformOfficeCounts counts;
  final List<PlatformOfficeOperator> operators;

  /// Exactly what a passenger browsing the Client app would see, read from the
  /// same sanitised `public_offices` view the Client app reads.
  ///
  /// Null when the office is not on the marketplace. That is not missing data —
  /// it is the answer: a passenger sees nothing. [marketplaceAbsenceReason]
  /// explains which of the two axes is responsible.
  final PlatformOfficeMarketplacePreview? marketplace;

  bool get isOnMarketplace => marketplace != null;

  /// Why the office is not visible to passengers, or null when it is.
  ///
  /// Reads the two axes separately and names the one at fault, because "not on
  /// the marketplace" has two very different causes and the remedy differs: a
  /// withdrawn office needs publishing, a suspended one needs reinstating first.
  String? get marketplaceAbsenceReason {
    if (isOnMarketplace) return null;
    if (office.status != 'active') {
      return 'المكتب ${office.statusLabel} — لا يظهر للعملاء حتى يُعاد تفعيله.';
    }
    return switch (office.listingStatus) {
      'draft' => 'المكتب قيد التجهيز ولم يُعرض في السوق بعد.',
      'unlisted' => 'تم سحب المكتب من السوق، ولا يظهر للعملاء حالياً.',
      _ => 'المكتب غير معروض في سوق العملاء.',
    };
  }
}

/// Operational magnitudes. Counts only — never the rows behind them.
class PlatformOfficeCounts {
  const PlatformOfficeCounts({
    this.operators = 0,
    this.drivers = 0,
    this.vehicles = 0,
    this.routes = 0,
    this.trips = 0,
    this.bookings = 0,
    this.reviews = 0,
  });

  final int operators;
  final int drivers;
  final int vehicles;
  final int routes;
  final int trips;
  final int bookings;
  final int reviews;

  /// Whether the office has ever actually traded, as opposed to merely existing.
  bool get hasTraded => bookings > 0 || trips > 0;
}

/// A dashboard user of the office.
///
/// No email and no password field, by design — dashboard logins are synthetic
/// `<username>@office.ewt.internal` addresses that receive no mail, so surfacing
/// one would leak a login handle while telling the reader nothing. Resetting a
/// password needs the Auth Admin API and therefore the service-role key, which
/// exists only inside the `platform-create-office` Edge Function; until an
/// equivalent function exists for resets, there is deliberately no path to one
/// from here.
class PlatformOfficeOperator {
  const PlatformOfficeOperator({
    required this.username,
    required this.fullName,
    required this.role,
    required this.status,
    this.createdAt,
  });

  final String username;
  final String fullName;

  /// `dashboard_admin` or `support_agent`.
  final String role;

  /// `active` or `disabled`.
  final String status;

  final DateTime? createdAt;

  bool get isActive => status == 'active';

  bool get isOwner => role == 'dashboard_admin';

  String get displayName =>
      fullName.trim().isEmpty ? username : fullName.trim();

  String get roleLabel => switch (role) {
    'dashboard_admin' => 'مالك المكتب',
    'support_agent' => 'خدمة العملاء',
    _ => role,
  };

  String get statusLabel => switch (status) {
    'active' => 'نشط',
    'disabled' => 'معطّل',
    _ => status,
  };
}

/// The office's marketplace card, exactly as `public_offices` exposes it.
///
/// The field set is the view's, not a re-derivation of it: phone, email and
/// status are absent here because they are absent there. If the view ever stops
/// exposing a column, this preview stops showing it too, rather than quietly
/// becoming a window onto data the client tier no longer receives.
class PlatformOfficeMarketplacePreview {
  const PlatformOfficeMarketplacePreview({
    required this.name,
    required this.slug,
    required this.description,
    required this.serviceAreas,
    required this.rating,
    required this.ratingsCount,
    this.logoUrl,
  });

  final String name;
  final String slug;
  final String description;
  final List<String> serviceAreas;
  final double rating;
  final int ratingsCount;
  final String? logoUrl;
}
