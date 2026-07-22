import 'platform_office.dart';

/// What the platform admin is currently looking for in the office list.
///
/// Applied in memory, over the list `platform_list_offices()` already returned.
/// That is the right shape *here* and would be the wrong shape almost anywhere
/// else in this dashboard: bookings and trips grow without bound and are filtered
/// server-side for that reason, but offices are the platform's own tenants —
/// onboarded one at a time by a human, through an Edge Function, with an
/// auth account minted per office. A platform with a thousand offices is a
/// different business, and will want pagination in the RPC when it arrives.
/// Filtering the fetched list keeps the RPC single-purpose until then.
///
/// The two status axes stay separate, exactly as they are in the database: an
/// operator asking for "suspended" offices and one asking for "withdrawn" offices
/// are asking different questions, and collapsing them into one dropdown would
/// make the answer to either unreliable.
class PlatformOfficeFilter {
  const PlatformOfficeFilter({
    this.query = '',
    this.status,
    this.listingStatus,
  });

  /// Free text, matched against name, slug, service areas and owner.
  final String query;

  /// Operational status — `active`, `paused`, `suspended`, `archived`.
  /// Null means "any".
  final String? status;

  /// Marketplace visibility — `draft`, `listed`, `unlisted`. Null means "any".
  final String? listingStatus;

  bool get isEmpty =>
      query.trim().isEmpty && status == null && listingStatus == null;

  /// `null` clears a facet, which is indistinguishable from "not passed" in a
  /// normal copyWith — hence the explicit clear flags rather than sentinel values.
  PlatformOfficeFilter copyWith({
    String? query,
    String? status,
    String? listingStatus,
    bool clearStatus = false,
    bool clearListingStatus = false,
  }) => PlatformOfficeFilter(
    query: query ?? this.query,
    status: clearStatus ? null : (status ?? this.status),
    listingStatus: clearListingStatus
        ? null
        : (listingStatus ?? this.listingStatus),
  );

  List<PlatformOffice> apply(List<PlatformOffice> offices) {
    final needle = query.trim().toLowerCase();
    return [
      for (final office in offices)
        if (_matches(office, needle)) office,
    ];
  }

  bool _matches(PlatformOffice office, String needle) {
    if (status != null && office.status != status) return false;
    if (listingStatus != null && office.listingStatus != listingStatus) {
      return false;
    }
    if (needle.isEmpty) return true;

    // Slug and owner are searchable alongside the name because they are how an
    // office is actually referred to elsewhere: the slug appears in support
    // threads and URLs, the owner is who the platform spoke to.
    return office.name.toLowerCase().contains(needle) ||
        office.slug.toLowerCase().contains(needle) ||
        (office.ownerName ?? '').toLowerCase().contains(needle) ||
        (office.ownerUsername ?? '').toLowerCase().contains(needle) ||
        office.serviceAreas.any((a) => a.toLowerCase().contains(needle));
  }
}
