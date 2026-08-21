import '../../domain/entities/customer_activity.dart';
import '../../domain/entities/customer_payment.dart';
import '../../domain/entities/customer_profile.dart';
import '../../domain/entities/customer_subscription.dart';
import '../../domain/entities/customer_trip.dart';

/// Page size for the two paged tabs inside a profile. Smaller than the
/// directory's: these lists sit inside a workspace beside other content, and a
/// 25-row table would push the tab strip off the top of the window.
const int customerTripsPageSize = 10;
const int customerPaymentsPageSize = 10;

/// The activity feed is a **window**, not a page — reaching further back is a
/// query this module deliberately does not make, because the tabs beside it
/// already hold the full history by category. A feed that returns exactly this
/// many rows says so on screen rather than implying it is complete.
const int customerActivityLimit = 40;

/// The Customer 360's five surfaces.
enum CustomerProfileTab {
  overview('نظرة عامة'),
  trips('الرحلات'),
  subscriptions('الاشتراكات'),
  payments('المدفوعات'),
  activity('النشاط');

  const CustomerProfileTab(this.label);

  final String label;
}

/// One lazily-loaded tab's status.
///
/// Each tab owns its own loading flag and its own error, which is what makes
/// partial failure survivable: المدفوعات failing must leave الرحلات on screen
/// and the header intact, because the operator opened the profile to answer a
/// question that the working tabs may already answer.
class CustomerTabStatus {
  final bool loaded;
  final bool loading;
  final String? error;

  const CustomerTabStatus({
    this.loaded = false,
    this.loading = false,
    this.error,
  });

  CustomerTabStatus copyWith({
    bool? loaded,
    bool? loading,
    String? error,
    bool clearError = false,
  }) => CustomerTabStatus(
    loaded: loaded ?? this.loaded,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
  );

  /// True when this tab has nothing to show and a reason for it.
  bool get failed => error != null && !loaded;
}

sealed class CustomerProfileState {
  const CustomerProfileState();
}

class CustomerProfileLoadingState extends CustomerProfileState {
  const CustomerProfileLoadingState();
}

class CustomerProfileErrorState extends CustomerProfileState {
  final String message;

  const CustomerProfileErrorState(this.message);
}

/// The loaded workspace.
///
/// Only the *profile* fetch can produce [CustomerProfileErrorState] — it is the
/// header, the summary and the identity, so without it there is no page. Every
/// tab below it fails into its own [CustomerTabStatus].
class CustomerProfileLoadedState extends CustomerProfileState {
  final CustomerProfile profile;
  final CustomerProfileTab tab;

  /// True while the header is being re-read after a manual refresh. The page
  /// stays up; only the affordance changes.
  final bool refreshing;

  // ── الرحلات ──────────────────────────────────────────────────────────────
  /// Upcoming and past are separate pages of separate queries, because they are
  /// ordered in opposite directions and the operator switches between them
  /// rather than scrolling from one into the other.
  final CustomerTripsPage upcomingTrips;
  final CustomerTripsPage pastTrips;
  final bool showPastTrips;
  final int tripsPageIndex;
  final CustomerTabStatus tripsStatus;

  // ── الاشتراكات ───────────────────────────────────────────────────────────
  final List<CustomerSubscription> subscriptions;
  final CustomerTabStatus subscriptionsStatus;

  // ── المدفوعات ────────────────────────────────────────────────────────────
  final CustomerPaymentsPage payments;
  final int paymentsPageIndex;
  final CustomerTabStatus paymentsStatus;

  // ── النشاط ───────────────────────────────────────────────────────────────
  final List<CustomerActivityEvent> activity;
  final CustomerTabStatus activityStatus;

  const CustomerProfileLoadedState({
    required this.profile,
    this.tab = CustomerProfileTab.overview,
    this.refreshing = false,
    this.upcomingTrips = const CustomerTripsPage.empty(),
    this.pastTrips = const CustomerTripsPage.empty(),
    this.showPastTrips = false,
    this.tripsPageIndex = 0,
    this.tripsStatus = const CustomerTabStatus(),
    this.subscriptions = const [],
    this.subscriptionsStatus = const CustomerTabStatus(),
    this.payments = const CustomerPaymentsPage.empty(),
    this.paymentsPageIndex = 0,
    this.paymentsStatus = const CustomerTabStatus(),
    this.activity = const [],
    this.activityStatus = const CustomerTabStatus(),
  });

  /// The trips page currently selected by the قادمة / سابقة switch.
  CustomerTripsPage get visibleTrips =>
      showPastTrips ? pastTrips : upcomingTrips;

  int get tripsPageCount =>
      (visibleTrips.total / customerTripsPageSize).ceil().clamp(1, 99999);

  int get paymentsPageCount =>
      (payments.total / customerPaymentsPageSize).ceil().clamp(1, 99999);

  /// True when the feed came back exactly full, so the screen can say the
  /// window is a window rather than let it read as the whole history.
  bool get activityWindowed => activity.length >= customerActivityLimit;

  /// Names the tabs that failed, for the partial-data notice in the header. A
  /// tab the operator has not opened yet has not failed — it simply has not
  /// been asked.
  List<String> get failedSources => [
    if (tripsStatus.failed) CustomerProfileTab.trips.label,
    if (subscriptionsStatus.failed) CustomerProfileTab.subscriptions.label,
    if (paymentsStatus.failed) CustomerProfileTab.payments.label,
    if (activityStatus.failed) CustomerProfileTab.activity.label,
  ];

  CustomerProfileLoadedState copyWith({
    CustomerProfile? profile,
    CustomerProfileTab? tab,
    bool? refreshing,
    CustomerTripsPage? upcomingTrips,
    CustomerTripsPage? pastTrips,
    bool? showPastTrips,
    int? tripsPageIndex,
    CustomerTabStatus? tripsStatus,
    List<CustomerSubscription>? subscriptions,
    CustomerTabStatus? subscriptionsStatus,
    CustomerPaymentsPage? payments,
    int? paymentsPageIndex,
    CustomerTabStatus? paymentsStatus,
    List<CustomerActivityEvent>? activity,
    CustomerTabStatus? activityStatus,
  }) => CustomerProfileLoadedState(
    profile: profile ?? this.profile,
    tab: tab ?? this.tab,
    refreshing: refreshing ?? this.refreshing,
    upcomingTrips: upcomingTrips ?? this.upcomingTrips,
    pastTrips: pastTrips ?? this.pastTrips,
    showPastTrips: showPastTrips ?? this.showPastTrips,
    tripsPageIndex: tripsPageIndex ?? this.tripsPageIndex,
    tripsStatus: tripsStatus ?? this.tripsStatus,
    subscriptions: subscriptions ?? this.subscriptions,
    subscriptionsStatus: subscriptionsStatus ?? this.subscriptionsStatus,
    payments: payments ?? this.payments,
    paymentsPageIndex: paymentsPageIndex ?? this.paymentsPageIndex,
    paymentsStatus: paymentsStatus ?? this.paymentsStatus,
    activity: activity ?? this.activity,
    activityStatus: activityStatus ?? this.activityStatus,
  );
}
