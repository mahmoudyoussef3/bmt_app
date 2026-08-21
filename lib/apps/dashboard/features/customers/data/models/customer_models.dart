import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_activity.dart';
import '../../domain/entities/customer_payment.dart';
import '../../domain/entities/customer_profile.dart';
import '../../domain/entities/customer_subscription.dart';
import '../../domain/entities/customer_trip.dart';

/// Document → entity mapping for every العملاء surface.
///
/// The customer RPCs return one `jsonb` document per call rather than a table,
/// so there are no PostgREST row shapes to model — just decoding, in one place,
/// so "what does `active_subscription` look like" is answered here and nowhere
/// else.
///
/// Money and counts arrive as Postgres `numeric`/`bigint`, which the client
/// hands over as `num`, `int` or (for large values) `String`. The coercions
/// below absorb all three: a total that silently became 0 because a cast failed
/// is the worst kind of bug in a module whose whole job is counting.
abstract final class CustomerMapper {
  const CustomerMapper._();

  static double _money(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  /// Nullable money. Distinguishes "no wallet row" from "a balance of zero",
  /// which the wallet tab renders differently and must not confuse.
  static double? _moneyOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _int(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static String _text(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _textOrNull(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static List<Map<String, dynamic>> _rows(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
  }

  // ── Directory ────────────────────────────────────────────────────────────

  static CustomersOverview overview(Map<String, dynamic> json) =>
      CustomersOverview(
        totalCustomers: _int(json['total_customers']),
        activeCustomers: _int(json['active_customers']),
        withActiveSubscription: _int(json['with_active_subscription']),
        withUpcomingTrip: _int(json['with_upcoming_trip']),
        newCustomers: _int(json['new_customers']),
      );

  static CustomerDirectoryPage directory(Map<String, dynamic> json) =>
      CustomerDirectoryPage(
        total: _int(json['total']),
        rows: _rows(json['rows']).map(summary).toList(),
      );

  static CustomerSummary summary(Map<String, dynamic> json) => CustomerSummary(
    clientId: _text(json['client_id']),
    fullName: _text(json['full_name'], 'بدون اسم'),
    phone: _text(json['phone']),
    email: _textOrNull(json['email']),
    status: _text(json['status'], 'active'),
    joinedAt: _date(json['joined_at']) ?? DateTime.now(),
    bookingsTotal: _int(json['bookings_total']),
    bookingsCompleted: _int(json['bookings_completed']),
    bookingsCancelled: _int(json['bookings_cancelled']),
    firstBookingAt: _date(json['first_booking_at']),
    lastActivityAt: _date(json['last_activity_at']),
    nextTripDate: _date(json['next_trip_date']),
    activePackageName: _textOrNull(json['active_package_name']),
    activePackageEndDate: _date(json['active_package_end_date']),
    activePackageTripsCount: _intOrNull(json['active_package_trips_count']),
    activePackageTripsUsed: _intOrNull(json['active_package_trips_used']),
    totalPaid: _money(json['total_paid']),
    walletBalance: _moneyOrNull(json['wallet_balance']),
    walletStatus: _textOrNull(json['wallet_status']),
  );

  // ── Profile ──────────────────────────────────────────────────────────────

  static CustomerProfile profile(Map<String, dynamic> json) {
    final client =
        (json['client'] as Map?)?.cast<String, dynamic>() ?? const {};
    final metrics =
        (json['metrics'] as Map?)?.cast<String, dynamic>() ?? const {};
    final active = (json['active_subscription'] as Map?)
        ?.cast<String, dynamic>();

    return CustomerProfile(
      client: CustomerIdentity(
        clientId: _text(client['client_id']),
        fullName: _text(client['full_name'], 'بدون اسم'),
        phone: _text(client['phone']),
        email: _textOrNull(client['email']),
        status: _text(client['status'], 'active'),
        joinedAt: _date(client['joined_at']) ?? DateTime.now(),
      ),
      metrics: CustomerMetrics(
        bookingsTotal: _int(metrics['bookings_total']),
        bookingsUpcoming: _int(metrics['bookings_upcoming']),
        bookingsCompleted: _int(metrics['bookings_completed']),
        bookingsCancelled: _int(metrics['bookings_cancelled']),
        firstBookingAt: _date(metrics['first_booking_at']),
        lastBookingAt: _date(metrics['last_booking_at']),
        nextTripDate: _date(metrics['next_trip_date']),
        boardedCount: _int(metrics['boarded_count']),
        noShowCount: _int(metrics['no_show_count']),
        totalPaid: _money(metrics['total_paid']),
        paymentsCount: _int(metrics['payments_count']),
        lastPaymentAt: _date(metrics['last_payment_at']),
        subscriptionsTotal: _int(metrics['subscriptions_total']),
        activeSubscriptions: _int(metrics['active_subscriptions']),
        walletBalance: _moneyOrNull(metrics['wallet_balance']),
        walletStatus: _textOrNull(metrics['wallet_status']),
        walletCurrency: _textOrNull(metrics['wallet_currency']),
        lastWalletAt: _date(metrics['last_wallet_at']),
        reviewsCount: _int(metrics['reviews_count']),
        avgOfficeRating: _moneyOrNull(metrics['avg_office_rating']),
        ticketsTotal: _int(metrics['tickets_total']),
        ticketsOpen: _int(metrics['tickets_open']),
        refundsSettledAmount: _money(metrics['refunds_settled_amount']),
      ),
      activeSubscription: active == null ? null : subscription(active),
      topRoutes: _rows(json['top_routes'])
          .map(
            (row) => CustomerRoute(
              route: _text(row['route'], 'غير محدد'),
              trips: _int(row['trips']),
            ),
          )
          .toList(),
    );
  }

  // ── Tabs ─────────────────────────────────────────────────────────────────

  static CustomerTripsPage trips(Map<String, dynamic> json) =>
      CustomerTripsPage(
        total: _int(json['total']),
        rows: _rows(json['rows']).map(trip).toList(),
      );

  static CustomerTrip trip(Map<String, dynamic> json) => CustomerTrip(
    bookingId: _text(json['booking_id']),
    bookingNumber: _textOrNull(json['booking_number']),
    route: _text(json['route'], 'غير محدد'),
    tripDate: _date(json['trip_date']),
    tripTime: _textOrNull(json['trip_time']),
    seat: _textOrNull(json['seat']),
    pickupPointName: _textOrNull(json['pickup_point_name']),
    dropoffPointName: _textOrNull(json['dropoff_point_name']),
    status: _text(json['status'], 'reserved'),
    paymentStatus: _textOrNull(json['payment_status']),
    paymentAmount: _money(json['payment_amount']),
    paymentMethod: _textOrNull(json['payment_method']),
    cancelledAt: _date(json['cancelled_at']),
    cancellationReason: _textOrNull(json['cancellation_reason']),
    createdAt: _date(json['created_at']) ?? DateTime.now(),
    viaSubscription: json['via_subscription'] == true,
    viaPackage: json['via_package'] == true,
    subscriptionName: _textOrNull(json['subscription_name']),
    tripStatus: _textOrNull(json['trip_status']),
    tripCode: _textOrNull(json['trip_code']),
    boardingStatus: _textOrNull(json['boarding_status']),
    boardedAt: _date(json['boarded_at']),
    noShowReason: _textOrNull(json['no_show_reason']),
  );

  static CustomerSubscription subscription(Map<String, dynamic> json) =>
      CustomerSubscription(
        id: _text(json['id']),
        packageName: _text(json['package_name'], 'اشتراك'),
        routeName: _textOrNull(json['route_name']),
        status: _text(json['status'], 'active'),
        startDate: _date(json['start_date']),
        endDate: _date(json['end_date']),
        tripsCount: _int(json['trips_count']),
        tripsUsed: _int(json['trips_used']),
        tripsRemaining: _int(json['trips_remaining']),
        // Stays null when the server could not compute it (trips_count = 0).
        usagePercent: _moneyOrNull(json['usage_percent']),
        totalPrice: _money(json['total_price']),
        paidAmount: _money(json['paid_amount']),
        remainingAmount: _money(json['remaining_amount']),
        renewalsCount: _int(json['renewals_count']),
        paymentMethod: _textOrNull(json['payment_method']),
        paymentReviewStatus: _textOrNull(json['payment_review_status']),
        createdAt: _date(json['created_at']) ?? DateTime.now(),
        isCurrent: json['is_current'] == true,
      );

  static CustomerPaymentsPage payments(Map<String, dynamic> json) {
    final wallet = (json['wallet'] as Map?)?.cast<String, dynamic>();
    return CustomerPaymentsPage(
      total: _int(json['total']),
      rows: _rows(json['rows']).map(payment).toList(),
      totalApproved: _money(json['total_approved']),
      wallet: wallet == null
          ? null
          : CustomerWallet(
              balance: _money(wallet['balance']),
              availableBalance: _moneyOrNull(wallet['available_balance']),
              reservedBalance: _moneyOrNull(wallet['reserved_balance']),
              currency: _text(wallet['currency'], 'EGP'),
              status: _text(wallet['status'], 'active'),
              lifetimeCredited: _money(wallet['lifetime_credited']),
              lifetimeDebited: _money(wallet['lifetime_debited']),
            ),
      walletTransactions: _rows(
        json['wallet_transactions'],
      ).map(walletEntry).toList(),
    );
  }

  static CustomerPayment payment(Map<String, dynamic> json) => CustomerPayment(
    id: _text(json['id']),
    bookingId: _textOrNull(json['booking_id']),
    bookingNumber: _textOrNull(json['booking_number']),
    route: _textOrNull(json['route']),
    tripDate: _date(json['trip_date']),
    method: _text(json['method'], 'cash'),
    amount: _money(json['amount']),
    currency: _text(json['currency'], 'EGP'),
    status: _text(json['status'], 'submitted'),
    paymentReference: _textOrNull(json['payment_reference']),
    submittedAt: _date(json['submitted_at']),
    paidAt: _date(json['paid_at']),
    reviewedAt: _date(json['reviewed_at']),
    rejectionReason: _textOrNull(json['rejection_reason']),
  );

  static CustomerWalletEntry walletEntry(Map<String, dynamic> json) =>
      CustomerWalletEntry(
        id: _text(json['id']),
        kind: _text(json['kind']),
        category: _text(json['category']),
        amount: _money(json['amount']),
        currency: _text(json['currency'], 'EGP'),
        balanceAfter: _money(json['balance_after']),
        reason: _text(json['reason']),
        createdAt: _date(json['created_at']) ?? DateTime.now(),
        performedByName: _text(json['performed_by_name'], 'النظام'),
      );

  static List<CustomerActivityEvent> activity(dynamic json) => _rows(json)
      .map(
        (row) => CustomerActivityEvent(
          kind: CustomerActivityKind.fromWire(_text(row['kind'])),
          at: _date(row['at']) ?? DateTime.now(),
          subject: _textOrNull(row['subject']),
          reference: _textOrNull(row['reference']),
          amount: _moneyOrNull(row['amount']),
        ),
      )
      .toList();
}
