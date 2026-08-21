import 'package:flutter/foundation.dart';

/// Remembers which dashboard sections the operator collapsed, for the lifetime
/// of the signed-in session.
///
/// This is deliberately **in-memory and process-wide** rather than a cubit or an
/// inherited widget. A dashboard section is destroyed and rebuilt every time the
/// shell swaps modules — Trips → Fleet → Trips builds a brand new
/// `DashboardCollapsibleSection` element — so any state owned by the widget tree
/// is gone by the time the operator comes back. Keying off a stable
/// [DashboardSectionIds] string in a store that outlives the tree is what makes
/// "collapse the analytics strip once, and it stays collapsed while I work" true.
///
/// It is *not* persisted to disk: the requirement is per-session memory, and a
/// collapsed panel surviving a full app restart would hide data from an operator
/// who has forgotten they ever collapsed it.
class DashboardSectionStateStore {
  DashboardSectionStateStore._();

  static final DashboardSectionStateStore instance =
      DashboardSectionStateStore._();

  final Map<String, bool> _expandedById = <String, bool>{};

  /// The remembered state for [sectionId], or [fallback] when the operator has
  /// never touched this section in the current session.
  bool isExpanded(String sectionId, {required bool fallback}) =>
      _expandedById[sectionId] ?? fallback;

  /// Records an operator's expand/collapse decision.
  void setExpanded(String sectionId, bool expanded) {
    _expandedById[sectionId] = expanded;
  }

  /// Drops every remembered section state.
  ///
  /// Called on sign-out so the next operator on the same machine starts from the
  /// designed defaults rather than inheriting someone else's collapsed layout.
  void clear() => _expandedById.clear();

  @visibleForTesting
  Map<String, bool> get debugSnapshot => Map.unmodifiable(_expandedById);
}

/// Stable identifiers for every collapsible dashboard section.
///
/// Section state is keyed by string, and a typo would silently give a section a
/// private key that nothing else shares (harmless but useless) — or worse, make
/// two unrelated sections share one. Declaring them here means the analyzer
/// catches the typo and the full set of collapsible sections is greppable in one
/// place.
///
/// Naming: `<module>.<section>`.
class DashboardSectionIds {
  DashboardSectionIds._();

  static const homeActionRequired = 'home.actionRequired';
  static const homeRevenueTrend = 'home.revenueTrend';
  static const homeTodayTrips = 'home.todayTrips';
  static const homeRecentBookings = 'home.recentBookings';
  static const homeTopRoutes = 'home.topRoutes';
  static const homeFleetTeam = 'home.fleetTeam';
  static const homeRecentActivity = 'home.recentActivity';

  static const businessKpis = 'business.kpis';
  static const businessHealth = 'business.health';
  static const businessInsights = 'business.insights';
  static const businessFinancial = 'business.financial';
  static const businessOperational = 'business.operational';
  static const businessCustomers = 'business.customers';
  static const businessQuickActions = 'business.quickActions';
  static const businessAttention = 'business.attention';

  static const tripsHeader = 'trips.header';
  static const tripsFilters = 'trips.filters';
  static const tripsStatusMix = 'trips.statusMix';
  static const tripsOccupancy = 'trips.occupancy';
  static const tripsTopRoutes = 'trips.topRoutes';

  static const bookingsHeader = 'bookings.header';
  static const bookingsFilters = 'bookings.filters';
  static const bookingsAnalytics = 'bookings.analytics';
  static const bookingsStatusMix = 'bookings.statusMix';
  static const bookingsPaymentMix = 'bookings.paymentMix';
  static const bookingsDailyTrend = 'bookings.dailyTrend';
  static const bookingsTopRoutes = 'bookings.topRoutes';

  static const customersHeader = 'customers.header';
  static const customersFilters = 'customers.filters';
  static const customerProfileInsights = 'customers.profile.insights';
  static const customerProfileRoutes = 'customers.profile.routes';
  static const customerProfileBehaviour = 'customers.profile.behaviour';

  static const subscriptionsHeader = 'subscriptions.header';
  static const subscriptionsFilters = 'subscriptions.filters';
  static const subscriptionsStatus = 'subscriptions.status';
  static const subscriptionsRevenueTrend = 'subscriptions.revenueTrend';
  static const subscriptionsByPlan = 'subscriptions.byPlan';
  static const subscriptionsByRoute = 'subscriptions.byRoute';
  static const subscriptionDetailInfo = 'subscriptions.detail.info';
  static const subscriptionDetailRides = 'subscriptions.detail.rides';
  static const subscriptionDetailAccount = 'subscriptions.detail.account';
  static const subscriptionDetailLedger = 'subscriptions.detail.ledger';
  static const subscriptionDetailOrigin = 'subscriptions.detail.origin';
  static const subscriptionDetailActions = 'subscriptions.detail.actions';

  static const fleetDriverReadiness = 'fleet.driverReadiness';
  static const fleetVehicleStatus = 'fleet.vehicleStatus';
  static const fleetAttention = 'fleet.attention';
  static const fleetActivity = 'fleet.activity';

  static const financeHeader = 'finance.header';
  static const financeAttention = 'finance.attention';
  static const financeMoneyStatus = 'finance.moneyStatus';
  static const financeRevenueTrend = 'finance.revenueTrend';
  static const financeRevenueSources = 'finance.revenueSources';
  static const financePaymentMethods = 'finance.paymentMethods';
  static const financeTopRoutes = 'finance.topRoutes';
  static const financeTopCustomers = 'finance.topCustomers';
  static const financeCumulativeRevenue = 'finance.cumulativeRevenue';
  static const financeWeekdayPerformance = 'finance.weekdayPerformance';
  static const financeDailyVolume = 'finance.dailyVolume';
  static const financePeriodComparison = 'finance.periodComparison';
  static const financeStatusMix = 'finance.statusMix';
  static const financeKpis = 'finance.kpis';
  static const financeStatements = 'finance.statements';
  static const financeCollectionByMethod = 'finance.collectionByMethod';
  static const financeRefundRequests = 'finance.refundRequests';
  static const financeIncomeStatement = 'finance.incomeStatement';

  static const usersFilters = 'users.filters';

  static const paymentVerificationFilters = 'paymentVerification.filters';

  static const reviewsHeader = 'reviews.header';
  static const reviewsFilters = 'reviews.filters';
  static const reviewsDriverStandings = 'reviews.driverStandings';

  static const walletHeader = 'wallet.header';
  static const walletDirectory = 'wallet.directory';
  static const walletActivity = 'wallet.activity';
  static const walletRefundQueue = 'wallet.refundQueue';
  static const walletDetailLedger = 'wallet.detail.ledger';

  static const liveOpsHeader = 'liveOps.header';
  static const liveOpsMap = 'liveOps.map';
  static const liveOpsTrips = 'liveOps.trips';
  static const liveOpsIncidents = 'liveOps.incidents';

  static const referralsHeader = 'referrals.header';
  static const referralsStatusMix = 'referrals.statusMix';
  static const referralsRewardMix = 'referrals.rewardMix';

  static const officeBillingHeader = 'officeBilling.header';
  static const officeBillingUsage = 'officeBilling.usage';
  static const officeBillingPlan = 'officeBilling.plan';
  static const officeBillingInvoices = 'officeBilling.invoices';

  static const platformLicensingHeader = 'platform.licensing.header';
  static const platformAuditLog = 'platform.audit.log';
  static const platformBillingRenewals = 'platform.billing.renewals';
  static const platformBillingInvoices = 'platform.billing.invoices';
  // The six `platform.licenses.*` ids are gone: the office workspace's panels
  // are tabs now, and a tab that also folds is a control that hides a control.

  static const ticketsHeader = 'tickets.header';
  static const officeProfileHeader = 'officeProfile.header';

  /// One entry in a plan's revision history, keyed by the revision's own id.
  /// Per-row sections need an id derived from the row's own identity — a shared
  /// constant would make every row in the list collapse together.
  static String platformPlanRevision(String revisionId) =>
      'platform.plans.revision.$revisionId';
}
