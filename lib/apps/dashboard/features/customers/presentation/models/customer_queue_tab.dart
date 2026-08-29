import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_filters.dart';

/// The slices العملاء is browsed by, as the tab strip الحجوزات and الاشتراكات
/// are worked through.
///
/// A directory is not a work queue, so these are not queues — but they are the
/// four questions an office owner actually asks of its passenger list, they are
/// the four counts the module already loads, and they are what the KPI tiles
/// already filtered by. Promoting them to the shared strip is what lets the
/// three المبيعات modules open with the same control instead of two of them
/// having a tab bar and the third not.
///
/// ## The strip owns three filter dimensions, not all five
///
/// [CustomerFilters] has five narrowing axes. A tab sets *exactly* the
/// subscription / upcoming / activity trio and leaves search, account status
/// and sort alone, so switching tabs never silently drops the operator's
/// search. Selection is derived from those same three fields rather than
/// stored, which is what keeps the strip and the «التصفية» dropdowns from ever
/// disagreeing: they are the same state read twice.
///
/// A combination no tab represents — "بدون اشتراك ساري" plus "خامل" — leaves
/// no tab highlighted, which is the truthful answer. The collapsed filter
/// summary says what is in force in that case.
enum CustomerQueueTab {
  all('كل العملاء'),
  active('نشطون'),
  subscribed('لديهم اشتراك'),
  upcoming('رحلة قادمة');

  const CustomerQueueTab(this.label);

  final String label;

  /// The tab's own count, straight from the overview the module already loads.
  /// No tab shows a number the server did not produce.
  int countIn(CustomersOverview overview) => switch (this) {
    CustomerQueueTab.all => overview.totalCustomers,
    CustomerQueueTab.active => overview.activeCustomers,
    CustomerQueueTab.subscribed => overview.withActiveSubscription,
    CustomerQueueTab.upcoming => overview.withUpcomingTrip,
  };

  CustomerSubscriptionFilter get _subscription =>
      this == CustomerQueueTab.subscribed
      ? CustomerSubscriptionFilter.active
      : CustomerSubscriptionFilter.any;

  CustomerUpcomingFilter get _upcoming => this == CustomerQueueTab.upcoming
      ? CustomerUpcomingFilter.has
      : CustomerUpcomingFilter.any;

  CustomerActivityFilter get _activity => this == CustomerQueueTab.active
      ? CustomerActivityFilter.active
      : CustomerActivityFilter.any;

  /// This tab's predicate, laid over what the operator has already typed and
  /// chosen elsewhere.
  CustomerFilters applyTo(CustomerFilters current) => CustomerFilters(
    search: current.search,
    status: current.status,
    sort: current.sort,
    subscription: _subscription,
    upcoming: _upcoming,
    activity: _activity,
  );

  bool isSelectedBy(CustomerFilters filters) =>
      filters.subscription == _subscription &&
      filters.upcoming == _upcoming &&
      filters.activity == _activity;
}
