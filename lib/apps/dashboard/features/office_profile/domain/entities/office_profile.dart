/// The signed-in office's own row in `offices`.
///
/// This is the entity the Client app browses in the marketplace directory
/// (`public_offices`), so the fields below are split deliberately into two
/// groups: what the office may edit about itself, and what the platform owns.
///
/// * **Editable** — [name], [logoUrl], [description], [phone], [email] and
///   [serviceAreas]. These are the office's shopfront.
/// * **Platform-owned** — [slug] (a stable public identifier other rows key
///   off), [status] (an operator suspending or reactivating their own office
///   would defeat the point), [rating] / [ratingsCount] (maintained by a
///   trigger from `trip_reviews`, never typed in) and [joinCode].
///
/// RLS on `offices` allows a `dashboard_admin` to update any column of their
/// own row, so that split is enforced here in the UI rather than by the
/// database. The editable set is the one this feature ever writes.
class OfficeProfile {
  const OfficeProfile({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.serviceAreas,
    required this.status,
    required this.listingStatus,
    required this.rating,
    required this.ratingsCount,
    required this.joinCode,
    this.joinCodeReadFailed = false,
    this.logoUrl,
    this.phone,
    this.email,
    this.joinCodeRotatedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;

  /// Stable public identifier. Read-only here: it is unique platform-wide and
  /// changing it would silently break anything holding the old value.
  final String slug;

  final String description;

  /// Governorates / areas the office serves, shown on its marketplace card.
  final List<String> serviceAreas;

  /// Operational state: one of `active`, `paused`, `suspended`, `archived`.
  /// It decides whether the office can *work* — whether its staff can sign in,
  /// whether it can recruit captains. It is not, on its own, what puts the
  /// office in front of passengers; see [listingStatus].
  final String status;

  /// Marketplace visibility: one of `draft`, `listed`, `unlisted`.
  ///
  /// A separate axis from [status] on purpose. A newly onboarded office is
  /// `active` + `draft`: its own dashboard works from the first minute while it
  /// stays invisible to passengers until the platform publishes it. Read from
  /// the office's own row, which is the same value `public_offices` filters on —
  /// never inferred from [status], which would report a draft office as visible.
  final String listingStatus;

  final double rating;
  final int ratingsCount;

  /// The out-of-band code a captain types when requesting to join this office.
  /// Displayed so the operator can share it; never editable by hand, because
  /// it is uniquely indexed platform-wide. Rotated through an RPC, never an
  /// update statement the dashboard composes.
  final String joinCode;

  /// The code could not be read this time — a different statement from "this
  /// office has no code", and the two must not share one message. An office
  /// told "لم يُصدر كود" for what was really a failed RPC would go looking for
  /// a code that exists, and hand out nothing to its drivers meanwhile.
  final bool joinCodeReadFailed;

  /// Whether there is a code to show at all.
  bool get hasJoinCode => joinCode.trim().isNotEmpty;

  final String? logoUrl;
  final String? phone;
  final String? email;

  /// When the code was last rotated, read through `office_join_code_info()`
  /// (migration 20260830090000) — the column itself sits behind the same
  /// privilege revoke as `join_code`. Null on an office running against a
  /// database without that function, and on one whose code has never been
  /// rotated since it was issued: the card says which.
  final DateTime? joinCodeRotatedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Is the office on the client marketplace right now? The same conjunction
  /// `office_is_listed()` applies in the database, so the badge cannot claim a
  /// visibility the backend does not grant.
  bool get isListed => status == 'active' && listingStatus == 'listed';

  /// Onboarded but never published. The office works; passengers cannot see it.
  bool get isDraft => listingStatus == 'draft';

  bool get hasRatings => ratingsCount > 0;

  /// Arabic label for [status], matching the check constraint on the column.
  String get statusLabel => switch (status) {
    'active' => 'نشط',
    'paused' => 'متوقف مؤقتًا',
    'suspended' => 'موقوف',
    'archived' => 'مؤرشف',
    _ => status,
  };

  /// Arabic label for [listingStatus]. Wording matches the platform admin's
  /// office list, so both sides of the platform name the same state alike.
  String get listingLabel => switch (listingStatus) {
    'draft' => 'قيد التجهيز',
    'listed' => 'معروض في السوق',
    'unlisted' => 'مسحوب من السوق',
    _ => listingStatus,
  };

  /// What [listingStatus] means for this office in practice, written for the
  /// operator rather than for the platform: what passengers can see today, and
  /// who changes that.
  String get listingExplanation => switch (listingStatus) {
    'draft' =>
      'مكتبك لم يُنشر بعد في سوق EWT، فلا يظهر للعملاء ولا تظهر رحلاته في نتائج '
          'البحث. الملف قيد التجهيز والمراجعة من إدارة المنصة، ويتم النشر بعد '
          'اكتمال البيانات. لوحة التحكم تعمل بالكامل في هذه الأثناء: يمكنك إضافة '
          'الرحلات والسائقين واستقبال طلبات الكباتن.',
    'listed' =>
      'مكتبك معروض حالياً في سوق EWT: يظهر في دليل المكاتب ويستطيع العملاء '
          'تصفّح رحلاته والحجز عليها.',
    'unlisted' =>
      'مكتبك مسحوب مؤقتاً من سوق EWT بقرار من إدارة المنصة، فلا يظهر للعملاء '
          'الآن. المكتب ما زال يعمل: لوحة التحكم والحجوزات القائمة لم تتأثر.',
    _ => 'حالة ظهور المكتب في السوق: $listingStatus.',
  };

  /// What the office still has to fill in before its marketplace card looks
  /// complete. Drives the checklist on the profile screen — an office with a
  /// blank description and no logo is at a real disadvantage in the directory.
  List<String> get missingMarketplaceFields => [
    if (description.trim().isEmpty) 'وصف المكتب',
    if ((logoUrl ?? '').trim().isEmpty) 'شعار المكتب',
    if ((phone ?? '').trim().isEmpty) 'رقم التواصل',
    if (serviceAreas.isEmpty) 'مناطق الخدمة',
  ];

  /// Why EWT would refuse to publish this office, in the office's own words.
  ///
  /// Mirrors the `platform_set_office_listing` guard exactly (active status, a
  /// description, at least one service area — migration 20260721140000), so the
  /// office is told what would actually make it listable instead of only that it
  /// is not listed. Deliberately narrower than [missingMarketplaceFields]: the
  /// logo and the phone make a card *thin*, these three make it *refused*.
  List<String> get listingBlockers => [
    if (status != 'active') 'حالة تشغيل نشطة',
    if (description.trim().isEmpty) 'وصف المكتب',
    if (serviceAreas.isEmpty) 'مناطق الخدمة',
  ];

  /// Nothing stands between this office and the marketplace but the platform's
  /// own decision.
  bool get meetsListingRequirements => listingBlockers.isEmpty;

  OfficeProfile copyWith({
    String? name,
    String? description,
    List<String>? serviceAreas,
    String? logoUrl,
    String? phone,
    String? email,
  }) {
    return OfficeProfile(
      id: id,
      name: name ?? this.name,
      slug: slug,
      description: description ?? this.description,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      status: status,
      listingStatus: listingStatus,
      rating: rating,
      ratingsCount: ratingsCount,
      joinCode: joinCode,
      joinCodeReadFailed: joinCodeReadFailed,
      logoUrl: logoUrl ?? this.logoUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      joinCodeRotatedAt: joinCodeRotatedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// The subset of [OfficeProfile] this feature is allowed to write back.
///
/// A dedicated type rather than passing the whole entity: it makes the write
/// surface impossible to widen by accident, and keeps `status` / `rating` /
/// `join_code` out of every payload the datasource can build.
class OfficeProfileEdit {
  const OfficeProfileEdit({
    required this.name,
    required this.description,
    required this.serviceAreas,
    this.logoUrl,
    this.phone,
    this.email,
  });

  factory OfficeProfileEdit.fromProfile(OfficeProfile profile) {
    return OfficeProfileEdit(
      name: profile.name,
      description: profile.description,
      serviceAreas: profile.serviceAreas,
      logoUrl: profile.logoUrl,
      phone: profile.phone,
      email: profile.email,
    );
  }

  final String name;
  final String description;
  final List<String> serviceAreas;
  final String? logoUrl;
  final String? phone;
  final String? email;
}
