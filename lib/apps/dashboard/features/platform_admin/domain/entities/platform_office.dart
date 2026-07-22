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
    this.logoUrl,
    this.phone,
    this.email,
    this.listedAt,
    this.createdAt,
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

  final String? logoUrl;
  final String? phone;
  final String? email;
  final DateTime? listedAt;
  final DateTime? createdAt;

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
}
