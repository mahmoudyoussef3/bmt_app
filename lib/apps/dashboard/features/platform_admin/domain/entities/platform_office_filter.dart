import 'platform_analytics.dart';
import 'platform_office.dart';

/// How the office list is ordered.
///
/// The default stays [newest] — the order `platform_list_offices()` already
/// returns — so adding sorting does not silently rearrange a screen the
/// operator knows. The other three exist because "which office earns most",
/// "which is busiest" and "which has gone quiet longest" are the three
/// questions a platform admin actually opens this screen with, and none of them
/// can be answered by reading a list sorted by creation date.
enum PlatformOfficeSort {
  newest('الأحدث إنشاءً'),
  revenue('الأعلى إيراداً'),
  activity('الأكثر نشاطاً'),
  idle('الأطول خمولاً'),
  name('الاسم');

  const PlatformOfficeSort(this.label);
  final String label;

  /// Whether this ordering needs the analytics map. The three that do fall back
  /// to [newest] when analytics has not loaded or failed, rather than producing
  /// an arbitrary order that looks deliberate.
  bool get needsMetrics => this == revenue || this == activity || this == idle;
}

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
    this.activity,
    this.sort = PlatformOfficeSort.newest,
  });

  /// Free text, matched against name, slug, service areas and owner.
  final String query;

  /// Operational status — `active`, `paused`, `suspended`, `archived`.
  /// Null means "any".
  final String? status;

  /// Marketplace visibility — `draft`, `listed`, `unlisted`. Null means "any".
  final String? listingStatus;

  /// Trading behaviour — a third axis, independent of the two configuration
  /// ones. An office can be `active` and `listed` and still have taken no
  /// booking in a month, which is exactly the combination worth filtering to.
  /// Null means "any"; requires analytics to have loaded.
  final ActivityLevel? activity;

  final PlatformOfficeSort sort;

  bool get isEmpty =>
      query.trim().isEmpty &&
      status == null &&
      listingStatus == null &&
      activity == null &&
      sort == PlatformOfficeSort.newest;

  /// `null` clears a facet, which is indistinguishable from "not passed" in a
  /// normal copyWith — hence the explicit clear flags rather than sentinel values.
  PlatformOfficeFilter copyWith({
    String? query,
    String? status,
    String? listingStatus,
    ActivityLevel? activity,
    PlatformOfficeSort? sort,
    bool clearStatus = false,
    bool clearListingStatus = false,
    bool clearActivity = false,
  }) => PlatformOfficeFilter(
    query: query ?? this.query,
    status: clearStatus ? null : (status ?? this.status),
    listingStatus: clearListingStatus
        ? null
        : (listingStatus ?? this.listingStatus),
    activity: clearActivity ? null : (activity ?? this.activity),
    sort: sort ?? this.sort,
  );

  /// Filters, then orders.
  ///
  /// [metrics] is optional because the office list renders before the analytics
  /// call resolves. Without it the activity facet cannot exclude anything — so
  /// it doesn't, rather than emptying the list while the numbers are in flight —
  /// and the metric-dependent sorts fall back to [PlatformOfficeSort.newest].
  List<PlatformOffice> apply(
    List<PlatformOffice> offices, {
    Map<String, PlatformOfficeMetrics> metrics = const {},
  }) {
    final needle = query.trim().toLowerCase();
    final visible = [
      for (final office in offices)
        if (_matches(office, needle, metrics)) office,
    ];
    return _sorted(visible, metrics);
  }

  List<PlatformOffice> _sorted(
    List<PlatformOffice> offices,
    Map<String, PlatformOfficeMetrics> metrics,
  ) {
    if (sort == PlatformOfficeSort.newest ||
        (sort.needsMetrics && metrics.isEmpty)) {
      return offices;
    }

    final sorted = [...offices];
    switch (sort) {
      case PlatformOfficeSort.name:
        sorted.sort((a, b) => a.name.compareTo(b.name));
      case PlatformOfficeSort.revenue:
        sorted.sort(
          (a, b) => _revenue(b, metrics).compareTo(_revenue(a, metrics)),
        );
      case PlatformOfficeSort.activity:
        sorted.sort(
          (a, b) => _bookings(b, metrics).compareTo(_bookings(a, metrics)),
        );
      case PlatformOfficeSort.idle:
        sorted.sort(
          (a, b) => _idleDays(a, metrics).compareTo(_idleDays(b, metrics)),
        );
      case PlatformOfficeSort.newest:
        break;
    }
    return sorted;
  }

  double _revenue(
    PlatformOffice office,
    Map<String, PlatformOfficeMetrics> metrics,
  ) => metrics[office.id]?.revenueRecent ?? 0;

  int _bookings(
    PlatformOffice office,
    Map<String, PlatformOfficeMetrics> metrics,
  ) => metrics[office.id]?.recentBookings ?? 0;

  /// Negated days-since-last-booking, so a plain ascending sort puts the
  /// longest-idle office first. Offices that never traded return 1 — above
  /// every negative value, which lands them at the end.
  int _idleDays(
    PlatformOffice office,
    Map<String, PlatformOfficeMetrics> metrics,
  ) {
    final days = metrics[office.id]?.daysSinceLastBooking;
    return days == null ? 1 : -days;
  }

  bool _matches(
    PlatformOffice office,
    String needle,
    Map<String, PlatformOfficeMetrics> metrics,
  ) {
    if (status != null && office.status != status) return false;
    if (listingStatus != null && office.listingStatus != listingStatus) {
      return false;
    }
    if (activity != null) {
      final level = metrics[office.id]?.activityLevel;

      if (level != null && level != activity) return false;
    }
    if (needle.isEmpty) return true;

    return office.name.toLowerCase().contains(needle) ||
        office.slug.toLowerCase().contains(needle) ||
        (office.ownerName ?? '').toLowerCase().contains(needle) ||
        (office.ownerUsername ?? '').toLowerCase().contains(needle) ||
        office.serviceAreas.any((a) => a.toLowerCase().contains(needle));
  }
}
