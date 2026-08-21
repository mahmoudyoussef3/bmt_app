import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_activity.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_filters.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_payment.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_profile.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_subscription.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/entities/customer_trip.dart';
import 'package:bmt_app/apps/dashboard/features/customers/domain/repositories/customers_repository.dart';

/// A fixed "now" so every relative label in these tests is deterministic.
final testNow = DateTime(2026, 8, 21, 12);

CustomerSummary summaryFixture({
  String clientId = 'client-1',
  String fullName = 'أحمد محمود',
  String phone = '+201000000001',
  String? email = 'ahmed@example.com',
  String status = 'active',
  int bookingsTotal = 12,
  int bookingsCompleted = 8,
  int bookingsCancelled = 1,
  DateTime? lastActivityAt,
  DateTime? nextTripDate,
  String? activePackageName = 'أسبوع عمل (٥ أيام)',
  int? activePackageTripsCount = 10,
  int? activePackageTripsUsed = 4,
  double totalPaid = 1250.5,
  double? walletBalance = 168,
}) => CustomerSummary(
  clientId: clientId,
  fullName: fullName,
  phone: phone,
  email: email,
  status: status,
  joinedAt: DateTime(2026, 1, 4),
  bookingsTotal: bookingsTotal,
  bookingsCompleted: bookingsCompleted,
  bookingsCancelled: bookingsCancelled,
  firstBookingAt: DateTime(2026, 1, 5),
  lastActivityAt: lastActivityAt ?? testNow.subtract(const Duration(hours: 3)),
  nextTripDate: nextTripDate,
  activePackageName: activePackageName,
  activePackageEndDate: DateTime(2026, 9, 30),
  activePackageTripsCount: activePackageTripsCount,
  activePackageTripsUsed: activePackageTripsUsed,
  totalPaid: totalPaid,
  walletBalance: walletBalance,
  walletStatus: walletBalance == null ? null : 'active',
);

CustomersOverview overviewFixture({
  int totalCustomers = 8,
  int activeCustomers = 3,
  int withActiveSubscription = 2,
  int withUpcomingTrip = 1,
  int newCustomers = 1,
}) => CustomersOverview(
  totalCustomers: totalCustomers,
  activeCustomers: activeCustomers,
  withActiveSubscription: withActiveSubscription,
  withUpcomingTrip: withUpcomingTrip,
  newCustomers: newCustomers,
);

CustomerProfile profileFixture({
  CustomerMetrics? metrics,
  CustomerSubscription? activeSubscription,
  List<CustomerRoute> topRoutes = const [
    CustomerRoute(route: 'القاهرة → الإسكندرية', trips: 5),
  ],
  String fullName = 'أحمد محمود',
}) => CustomerProfile(
  client: CustomerIdentity(
    clientId: 'client-1',
    fullName: fullName,
    phone: '+201000000001',
    email: 'ahmed@example.com',
    status: 'active',
    joinedAt: DateTime(2026, 1, 4),
  ),
  metrics: metrics ?? metricsFixture(),
  activeSubscription: activeSubscription,
  topRoutes: topRoutes,
);

CustomerMetrics metricsFixture({
  int bookingsTotal = 12,
  int bookingsUpcoming = 1,
  int bookingsCompleted = 8,
  int bookingsCancelled = 1,
  int boardedCount = 6,
  int noShowCount = 1,
  double totalPaid = 1250.5,
  int paymentsCount = 12,
  int subscriptionsTotal = 2,
  int activeSubscriptions = 1,
  double? walletBalance = 168,
  int reviewsCount = 2,
  double? avgOfficeRating = 4.5,
  int ticketsTotal = 1,
  int ticketsOpen = 0,
  DateTime? lastBookingAt,
  DateTime? lastPaymentAt,
  DateTime? nextTripDate,
}) => CustomerMetrics(
  bookingsTotal: bookingsTotal,
  bookingsUpcoming: bookingsUpcoming,
  bookingsCompleted: bookingsCompleted,
  bookingsCancelled: bookingsCancelled,
  firstBookingAt: DateTime(2026, 1, 5),
  lastBookingAt: lastBookingAt ?? testNow.subtract(const Duration(days: 2)),
  nextTripDate: nextTripDate,
  boardedCount: boardedCount,
  noShowCount: noShowCount,
  totalPaid: totalPaid,
  paymentsCount: paymentsCount,
  // Follows the booking date unless a test pins it: `lastActivityAt` is the
  // max of the three streams, so a fixed payment date would make every
  // "customer last seen N days ago" case unreachable.
  lastPaymentAt:
      lastPaymentAt ??
      lastBookingAt ??
      testNow.subtract(const Duration(days: 2)),
  subscriptionsTotal: subscriptionsTotal,
  activeSubscriptions: activeSubscriptions,
  walletBalance: walletBalance,
  walletStatus: walletBalance == null ? null : 'active',
  walletCurrency: walletBalance == null ? null : 'EGP',
  reviewsCount: reviewsCount,
  avgOfficeRating: avgOfficeRating,
  ticketsTotal: ticketsTotal,
  ticketsOpen: ticketsOpen,
);

CustomerSubscription subscriptionFixture({
  String id = 'sub-1',
  String packageName = 'أسبوع عمل (٥ أيام)',
  String status = 'active',
  int tripsCount = 10,
  int tripsUsed = 4,
  double? usagePercent = 40,
  bool isCurrent = true,
  DateTime? endDate,
}) => CustomerSubscription(
  id: id,
  packageName: packageName,
  routeName: 'القاهرة → الإسكندرية',
  status: status,
  startDate: DateTime(2026, 8, 1),
  endDate: endDate ?? DateTime(2026, 9, 30),
  tripsCount: tripsCount,
  tripsUsed: tripsUsed,
  tripsRemaining: (tripsCount - tripsUsed).clamp(0, tripsCount),
  usagePercent: usagePercent,
  totalPrice: 500,
  paidAmount: 500,
  remainingAmount: 0,
  createdAt: DateTime(2026, 8, 1),
  isCurrent: isCurrent,
);

CustomerTrip tripFixture({
  String bookingId = 'booking-1',
  String status = 'confirmed',
  String? paymentStatus = 'approved',
  String? boardingStatus = 'completed',
  DateTime? tripDate,
  String? subscriptionName,
}) => CustomerTrip(
  bookingId: bookingId,
  bookingNumber: 'BK-1234ABCD',
  route: 'القاهرة → الإسكندرية',
  tripDate: tripDate ?? DateTime(2026, 8, 19),
  tripTime: '12:00:00',
  seat: '13',
  pickupPointName: 'التجمع',
  dropoffPointName: 'سموحة',
  status: status,
  paymentStatus: paymentStatus,
  paymentAmount: 126,
  paymentMethod: 'instapay',
  createdAt: DateTime(2026, 8, 18),
  viaSubscription: subscriptionName != null,
  subscriptionName: subscriptionName,
  tripStatus: 'completed',
  tripCode: 'TR-960370',
  boardingStatus: boardingStatus,
  boardedAt: boardingStatus == 'completed'
      ? DateTime(2026, 8, 19, 12, 5)
      : null,
);

CustomerPayment paymentFixture({
  String id = 'pay-1',
  String status = 'approved',
  double amount = 126.75,
}) => CustomerPayment(
  id: id,
  bookingId: 'booking-1',
  bookingNumber: 'BK-1234ABCD',
  route: 'القاهرة → الإسكندرية',
  tripDate: DateTime(2026, 8, 19),
  method: 'instapay',
  amount: amount,
  currency: 'EGP',
  status: status,
  submittedAt: DateTime(2026, 8, 19, 13, 19),
  reviewedAt: DateTime(2026, 8, 19, 13, 20),
);

CustomerActivityEvent activityFixture({
  CustomerActivityKind kind = CustomerActivityKind.bookingCreated,
  DateTime? at,
  double? amount,
}) => CustomerActivityEvent(
  kind: kind,
  at: at ?? testNow.subtract(const Duration(hours: 2)),
  subject: 'القاهرة → الإسكندرية',
  reference: 'BK-1234ABCD',
  amount: amount,
);

/// Hand-written fake, no mocking framework — the console's standing convention.
///
/// Records every call so a test can assert *what was not fetched* as well as
/// what was: the profile tabs are lazy, and "الاشتراكات was never requested"
/// is the assertion that proves it.
class FakeCustomersRepository implements CustomersRepository {
  final List<String> calls = [];

  CustomersOverview overview = overviewFixture();
  CustomerDirectoryPage directory = CustomerDirectoryPage(
    total: 1,
    rows: [summaryFixture()],
  );
  CustomerProfile profile = profileFixture();
  CustomerTripsPage upcomingTrips = const CustomerTripsPage.empty();
  CustomerTripsPage pastTrips = CustomerTripsPage(
    total: 1,
    rows: [tripFixture()],
  );
  List<CustomerSubscription> subscriptions = [subscriptionFixture()];
  CustomerPaymentsPage payments = CustomerPaymentsPage(
    total: 1,
    rows: [paymentFixture()],
    totalApproved: 126.75,
  );
  List<CustomerActivityEvent> activity = [activityFixture()];

  /// Per-method failure switches, so a test can break exactly one feed.
  final Set<String> failing = {};

  /// The last filters the directory was asked for — the assertion that proves
  /// filtering is a server request rather than a Dart list operation.
  CustomerFilters? lastFilters;
  int? lastOffset;
  int? lastLimit;

  /// Optional gate to hold a call open, for out-of-order response tests.
  final Map<String, Future<void> Function()> gates = {};

  Future<void> _guard(String name) async {
    calls.add(name);
    final gate = gates[name];
    if (gate != null) await gate();
    if (failing.contains(name)) throw Exception('فشل $name');
  }

  @override
  Future<CustomersOverview> getOverview() async {
    await _guard('overview');
    return overview;
  }

  @override
  Future<CustomerDirectoryPage> getDirectory({
    required CustomerFilters filters,
    required int limit,
    required int offset,
  }) async {
    lastFilters = filters;
    lastLimit = limit;
    lastOffset = offset;
    await _guard('directory');
    return directory;
  }

  @override
  Future<CustomerProfile> getProfile(String clientId) async {
    await _guard('profile');
    return profile;
  }

  @override
  Future<CustomerTripsPage> getTrips(
    String clientId, {
    required bool upcoming,
    required int limit,
    required int offset,
  }) async {
    await _guard(upcoming ? 'trips:upcoming' : 'trips:past');
    return upcoming ? upcomingTrips : pastTrips;
  }

  @override
  Future<List<CustomerSubscription>> getSubscriptions(String clientId) async {
    await _guard('subscriptions');
    return subscriptions;
  }

  @override
  Future<CustomerPaymentsPage> getPayments(
    String clientId, {
    required int limit,
    required int offset,
  }) async {
    await _guard('payments');
    return payments;
  }

  @override
  Future<List<CustomerActivityEvent>> getActivity(String clientId) async {
    await _guard('activity');
    return activity;
  }
}
