/// What the operator narrowed the directory to.
///
/// Every filter here maps to a predicate the server applies inside
/// `office_customer_directory`. None of them is evaluated in Dart: filtering a
/// page that has already been cut to 25 rows would silently disagree with the
/// count beside it.
///
/// Four filters, deliberately. Each answers a question an office owner actually
/// asks about a passenger — do they have a package, are they travelling soon,
/// are they still with us, is their account in order.
enum CustomerSubscriptionFilter {
  any('الكل', null),
  active('لديه اشتراك ساري', 'active'),
  none('بدون اشتراك ساري', 'none');

  const CustomerSubscriptionFilter(this.label, this.wire);

  final String label;
  final String? wire;
}

enum CustomerUpcomingFilter {
  any('الكل', null),
  has('لديه رحلة قادمة', 'has'),
  none('لا توجد رحلات قادمة', 'none');

  const CustomerUpcomingFilter(this.label, this.wire);

  final String label;
  final String? wire;
}

/// "Active" and "dormant" are windows on the same timestamp, and they are
/// deliberately not complements: a customer last seen 45 days ago is neither.
/// Calling them opposites would make the two counts sum to more than the base
/// and invite the owner to read the gap as a contradiction.
enum CustomerActivityFilter {
  any('الكل', null),
  active('نشط خلال ٣٠ يوماً', 'active'),
  dormant('خامل منذ ٩٠ يوماً', 'dormant');

  const CustomerActivityFilter(this.label, this.wire);

  final String label;
  final String? wire;
}

enum CustomerSort {
  recent('الأحدث نشاطاً', 'recent'),
  name('الاسم', 'name'),
  bookings('الأكثر حجزاً', 'bookings'),
  upcoming('أقرب رحلة', 'upcoming'),
  paid('الأعلى إنفاقاً', 'paid');

  const CustomerSort(this.label, this.wire);

  final String label;
  final String wire;
}

class CustomerFilters {
  final String search;
  final CustomerSubscriptionFilter subscription;
  final CustomerUpcomingFilter upcoming;
  final CustomerActivityFilter activity;

  /// `clients.status`. Null is "any"; the value is passed through untranslated
  /// because it is the database's own vocabulary.
  final String? status;

  final CustomerSort sort;

  const CustomerFilters({
    this.search = '',
    this.subscription = CustomerSubscriptionFilter.any,
    this.upcoming = CustomerUpcomingFilter.any,
    this.activity = CustomerActivityFilter.any,
    this.status,
    this.sort = CustomerSort.recent,
  });

  /// How many narrowing choices are in force, for the "filters applied" badge.
  /// The sort is not a filter — it changes the order, not the population.
  int get activeCount => [
    search.trim().isNotEmpty,
    subscription != CustomerSubscriptionFilter.any,
    upcoming != CustomerUpcomingFilter.any,
    activity != CustomerActivityFilter.any,
    status != null,
  ].where((applied) => applied).length;

  bool get isEmpty => activeCount == 0;

  /// True when the operator typed something. Distinguishes "no customers yet"
  /// from "no customers matching", which are different empty states.
  bool get isSearching => search.trim().isNotEmpty;

  CustomerFilters copyWith({
    String? search,
    CustomerSubscriptionFilter? subscription,
    CustomerUpcomingFilter? upcoming,
    CustomerActivityFilter? activity,
    String? status,
    bool clearStatus = false,
    CustomerSort? sort,
  }) => CustomerFilters(
    search: search ?? this.search,
    subscription: subscription ?? this.subscription,
    upcoming: upcoming ?? this.upcoming,
    activity: activity ?? this.activity,
    status: clearStatus ? null : (status ?? this.status),
    sort: sort ?? this.sort,
  );
}
