/// An office as the EWT platform sees it — including the ones no client can.
///
/// `platform_list_offices()` is the only surface that returns draft, paused and
/// suspended offices: RLS on `offices` shows an operator their own row plus the
/// listed ones, which is deliberately the wrong set for the platform, since the
/// offices needing attention are exactly the ones nobody can see.
///
/// The join code is absent on purpose. The platform admin receives it once, at
/// onboarding, to hand over; after that it belongs to the office, which reads it
/// through `office_join_code()` and rotates it itself.
class PlatformOffice {
  const PlatformOffice({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.serviceAreas,
    required this.status,
    required this.listingStatus,
    required this.rating,
    required this.ratingsCount,
    required this.operators,
    required this.drivers,
    required this.routes,
    this.vehicles = 0,
    this.trips = 0,
    this.ownerName,
    this.ownerUsername,
    this.logoUrl,
    this.phone,
    this.email,
    this.listedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final List<String> serviceAreas;

  /// Operational: `active`, `paused`, `suspended`, `archived`. Anything but
  /// `active` locks the office's own staff and captains out.
  final String status;

  /// Marketplace visibility: `draft`, `listed`, `unlisted`. Independent of
  /// [status] — a draft office works normally for its own operators.
  final String listingStatus;

  final double rating;
  final int ratingsCount;
  final int operators;
  final int drivers;
  final int routes;
  final int vehicles;

  /// Lifetime trips. The cheapest answer to "has this office ever traded", which
  /// is the question that separates an office still being set up from one that
  /// was set up and abandoned — both of which sit in `draft` looking identical.
  final int trips;

  /// The office's first active `dashboard_admin`, resolved server-side.
  ///
  /// Null when the office has no active admin — an office nobody can sign in to,
  /// which is a state worth seeing rather than papering over with a blank.
  final String? ownerName;
  final String? ownerUsername;

  final String? logoUrl;
  final String? phone;
  final String? email;
  final DateTime? listedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isListed => status == 'active' && listingStatus == 'listed';

  bool get isDraft => listingStatus == 'draft';

  String get statusLabel => switch (status) {
    'active' => 'نشط',
    'paused' => 'متوقف مؤقتًا',
    'suspended' => 'موقوف',
    'archived' => 'مؤرشف',
    _ => status,
  };

  String get listingLabel => switch (listingStatus) {
    'draft' => 'قيد التجهيز',
    'listed' => 'معروض في السوق',
    'unlisted' => 'مسحوب من السوق',
    _ => listingStatus,
  };

  /// Why `platform_set_office_listing` would refuse to publish this office.
  ///
  /// Mirrors the RPC's `office_profile_incomplete` guard exactly, so the button
  /// is disabled with a reason instead of the operator pressing it and reading a
  /// server error.
  List<String> get blockersToListing => [
    if (status != 'active') 'المكتب غير نشط',
    if (description.trim().isEmpty) 'وصف المكتب مفقود',
    if (serviceAreas.isEmpty) 'لم تُحدَّد مناطق الخدمة',
  ];

  bool get canBeListed => blockersToListing.isEmpty;

  /// The marketplace-card fields, and whether each is filled.
  ///
  /// Deliberately wider than [blockersToListing]: the RPC refuses to publish an
  /// office missing a description or service areas, but an office with those two
  /// and nothing else still reaches passengers as a card with no logo and no way
  /// to make contact. The blockers say what is *forbidden*; this says what is
  /// *thin*, which is the more useful thing to show before pressing publish.
  Map<String, bool> get profileFields => {
    'الوصف': description.trim().isNotEmpty,
    'مناطق الخدمة': serviceAreas.isNotEmpty,
    'الشعار': (logoUrl ?? '').trim().isNotEmpty,
    'رقم الهاتف': (phone ?? '').trim().isNotEmpty,
    'البريد الإلكتروني': (email ?? '').trim().isNotEmpty,
  };

  int get completedProfileFields =>
      profileFields.values.where((filled) => filled).length;

  int get totalProfileFields => profileFields.length;

  /// 0.0 – 1.0.
  double get profileCompleteness =>
      totalProfileFields == 0 ? 0 : completedProfileFields / totalProfileFields;

  List<String> get missingProfileFields => [
    for (final entry in profileFields.entries)
      if (!entry.value) entry.key,
  ];

  /// Who to contact about this office, falling back to the login handle when the
  /// account carries no full name.
  String? get ownerLabel {
    final name = ownerName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final username = ownerUsername?.trim() ?? '';
    return username.isEmpty ? null : username;
  }
}
