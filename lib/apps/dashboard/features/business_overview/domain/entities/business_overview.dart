/// The executive snapshot: everything the Business Overview tab shows, derived
/// from lists the other modules already load.
///
/// ## Two rules this entity is built on
///
/// **Nothing here is fabricated.** Every trend, ratio and insight is
/// re-bucketed from rows that are present in memory. The schema holds no
/// historical snapshot table, so where a comparison cannot be measured the
/// answer is a null [MetricTrend] or [BusinessHealthStatus.unknown] — never a
/// plausible-looking number.
///
/// **Nothing here is authoritative.** Finance owns the money statements, Trips
/// owns the schedule, the wallet owns the ledger. This page is a lens: it
/// re-reads their entities under the same documented rules so its figures agree
/// with theirs by construction, and it links out rather than restating.
/// The two rules it inherits verbatim, both from `SupabaseFinanceDatasource`:
/// realised booking revenue counts **approved payments only**, dated by
/// **`created_at`**. Home's revenue line uses the same pair, which is why the
/// two pages agree without either querying the other.
///
/// Every source is optional. An office whose plan does not include the wallet,
/// or whose live-ops query fails, still gets a working page with the affected
/// sources listed in [unavailable] — a partial answer beats an error screen on
/// the one page an owner opens first.
library;

import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/domain/entities/captain_request.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart'
    show RefundRequest, RefundStatus, RevenueMetrics;
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_money_model.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/entities/live_ops_snapshot.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/entities/booking_payment_verification.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/domain/entities/trip_review_entry.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/entities/complaint.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';

import 'business_attention.dart';
import 'business_health.dart';
import 'business_insight.dart';
import 'business_metric.dart';

/// One feed into the overview. Named so the page can say *which* number is
/// missing rather than quietly rendering a zero.
enum BusinessDataSource {
  trips('الرحلات'),
  bookings('الحجوزات'),
  paymentVerifications('مراجعة المدفوعات'),
  revenue('الإيرادات'),
  fleet('الأسطول'),
  tickets('الشكاوى'),
  reviews('التقييمات'),
  subscriptions('الاشتراكات'),
  captainRequests('طلبات الكباتن'),
  refunds('طلبات الاسترداد'),
  wallet('المحافظ'),
  liveOps('العمليات المباشرة');

  final String label;

  const BusinessDataSource(this.label);
}

/// How full one route ran over the measured window.
class RouteStanding {
  final String route;
  final int bookedSeats;
  final int capacity;
  final int trips;

  const RouteStanding({
    required this.route,
    required this.bookedSeats,
    required this.capacity,
    required this.trips,
  });

  double get occupancyRate => capacity == 0 ? 0 : bookedSeats / capacity;
}

/// The customer the office earned the most from in the measured window.
class TopCustomer {
  final String clientId;
  final String name;
  final double spend;
  final int bookings;

  const TopCustomer({
    required this.clientId,
    required this.name,
    required this.spend,
    required this.bookings,
  });
}

class BusinessOverview {
  final List<OperationTrip> trips;
  final List<OperationBooking> bookings;
  final List<BookingPaymentVerification> paymentVerifications;
  final List<SupportTicket> tickets;
  final List<TripReviewEntry> reviews;
  final List<UserSubscription> subscriptions;
  final List<CaptainRequest> captainRequests;
  final List<RefundRequest> refundRequests;
  final FleetWorkspace? fleet;
  final RevenueMetrics? revenue;
  final WalletFinancePosition? wallet;
  final LiveOpsSnapshot? liveOps;

  /// Feeds that did not answer. Rendered as a note on the page, so a zero the
  /// owner sees is always a measured zero.
  final Set<BusinessDataSource> unavailable;

  /// When this snapshot was assembled. Every "today", "yesterday" and rolling
  /// window below is measured from here rather than from `DateTime.now()`, so
  /// the whole page describes one instant and stays testable.
  final DateTime generatedAt;

  BusinessOverview({
    this.trips = const [],
    this.bookings = const [],
    this.paymentVerifications = const [],
    this.tickets = const [],
    this.reviews = const [],
    this.subscriptions = const [],
    this.captainRequests = const [],
    this.refundRequests = const [],
    this.fleet,
    this.revenue,
    this.wallet,
    this.liveOps,
    this.unavailable = const {},
    required this.generatedAt,
  });

  bool has(BusinessDataSource source) => !unavailable.contains(source);

  late final DateTime _today = _startOfDay(generatedAt);

  /// Buckets [days] days ending on today, oldest first, quiet days as zeros.
  ///
  /// [valueOf] contributes to the bucket for [dayOf]; rows outside the window
  /// are skipped. [combine] folds the per-day totals — a sum for money and
  /// counts, a ratio for occupancy, which is why it is not hard-coded.
  List<DailyMetric> _series<T>({
    required int days,
    required Iterable<T> rows,
    required DateTime? Function(T row) dayOf,
    required void Function(_DayBucket bucket, T row) accumulate,
    required double Function(_DayBucket bucket) combine,
  }) {
    final first = _today.subtract(Duration(days: days - 1));
    final buckets = <DateTime, _DayBucket>{
      for (var i = 0; i < days; i++) first.add(Duration(days: i)): _DayBucket(),
    };

    for (final row in rows) {
      final at = dayOf(row);
      if (at == null) continue;
      final day = _startOfDay(at);
      final bucket = buckets[day];
      if (bucket == null) continue;
      accumulate(bucket, row);
    }

    return [
      for (final entry in buckets.entries)
        DailyMetric(day: entry.key, value: combine(entry.value)),
    ];
  }

  /// Collected booking revenue per day — approved payments only, dated by
  /// `created_at`. Same two rules the Finance module uses for realised revenue.
  List<DailyMetric> revenueSeries({int days = 7}) => _series(
    days: days,
    rows: bookings.where((b) => b.paymentStatus == PaymentStatus.approved),
    dayOf: (b) => b.createdAt,
    accumulate: (bucket, b) => bucket.total += b.paymentAmount,
    combine: (bucket) => bucket.total,
  );

  /// Bookings **taken** per day, by `created_at`. Note this is not Home's
  /// "الحجوزات اليوم", which counts bookings *travelling* today — an owner
  /// asking how sales are going means the former.
  List<DailyMetric> bookingsSeries({int days = 7}) => _series(
    days: days,
    rows: bookings,
    dayOf: (b) => b.createdAt,
    accumulate: (bucket, _) => bucket.count += 1,
    combine: (bucket) => bucket.count.toDouble(),
  );

  /// Trips scheduled per day, cancellations excluded — a cancelled bus was
  /// never operating capacity.
  List<DailyMetric> tripsSeries({int days = 7}) => _series(
    days: days,
    rows: trips.where((t) => t.status != OperationTripStatus.cancelled),
    dayOf: (t) => t.scheduledAt,
    accumulate: (bucket, _) => bucket.count += 1,
    combine: (bucket) => bucket.count.toDouble(),
  );

  /// Seats sold ÷ seats offered per day, as a `0..1` ratio. A day with no
  /// capacity on offer reads as zero rather than dividing by nothing.
  List<DailyMetric> occupancySeries({int days = 7}) => _series(
    days: days,
    rows: trips.where((t) => t.status != OperationTripStatus.cancelled),
    dayOf: (t) => t.scheduledAt,
    accumulate: (bucket, t) {
      bucket.total += t.bookedSeats;
      bucket.capacity += t.capacity;
    },
    combine: (bucket) => bucket.capacity == 0 ? 0 : bucket.total / bucket.capacity,
  );

  /// Net movement of customer wallet balances per day. Signed: a day of
  /// cashback grants reads positive, a day of spending reads negative.
  List<DailyMetric> walletSeries({int days = 7}) => _series(
    days: days,
    rows: wallet?.movements ?? const <WalletMovement>[],
    dayOf: (m) => m.date,
    accumulate: (bucket, m) => bucket.total += m.amount,
    combine: (bucket) => bucket.total,
  );

  /// Compares the last point of [series] with the one before it.
  ///
  /// Null when the series is too short to hold a comparison — the caller then
  /// renders the value with no arrow, which is the honest rendering.
  MetricTrend? _dayOverDay(List<DailyMetric> series) {
    if (series.length < 2) return null;
    return MetricTrend(
      current: series.last.value,
      previous: series[series.length - 2].value,
      previousLabel: 'أمس',
    );
  }

  /// The day this office's history starts, as far as the loaded rows know.
  late final DateTime? _firstBookingDay = bookings.isEmpty
      ? null
      : _startOfDay(
          bookings
              .map((b) => b.createdAt)
              .reduce((a, b) => a.isBefore(b) ? a : b),
        );

  /// Compares the last 7 days against the 7 before them.
  ///
  /// Null when the office is younger than the baseline window. The series
  /// itself always returns fourteen buckets — quiet days are zeros by design —
  /// so length proves nothing; what has to be checked is whether the office
  /// actually existed for the earlier week. Without this an office in its first
  /// fortnight reads as a business whose revenue just collapsed to nothing,
  /// which is the exact class of fabricated trend this page refuses to show.
  MetricTrend? _weekOverWeek(List<DailyMetric> fortnight) {
    if (fortnight.length < 14) return null;
    final start = _firstBookingDay;
    if (start == null || start.isAfter(fortnight.first.day)) return null;

    double sum(List<DailyMetric> days) =>
        days.fold<double>(0, (acc, day) => acc + day.value);
    return MetricTrend(
      current: sum(fortnight.sublist(fortnight.length - 7)),
      previous: sum(
        fortnight.sublist(fortnight.length - 14, fortnight.length - 7),
      ),
      previousLabel: 'الأسبوع الماضي',
    );
  }

  late final List<DailyMetric> revenueWeek = revenueSeries();
  late final List<DailyMetric> bookingsWeek = bookingsSeries();
  late final List<DailyMetric> tripsWeek = tripsSeries();
  late final List<DailyMetric> occupancyWeek = occupancySeries();
  late final List<DailyMetric> walletWeek = walletSeries();

  double get revenueToday => revenueWeek.last.value;
  MetricTrend? get revenueTrend => _dayOverDay(revenueWeek);

  int get bookingsToday => bookingsWeek.last.value.round();
  MetricTrend? get bookingsTrend => _dayOverDay(bookingsWeek);

  double get walletChangeToday => walletWeek.last.value;
  MetricTrend? get walletTrend => _dayOverDay(walletWeek);

  /// Revenue over the last 7 days against the 7 before — the comparison the
  /// health panel grades, and the one least distorted by a single quiet day.
  late final MetricTrend? revenueWeekTrend = _weekOverWeek(
    revenueSeries(days: 14),
  );

  late final List<OperationTrip> todayTrips = trips.where((trip) {
    final at = trip.scheduledAt;
    return at != null && _startOfDay(at) == _today;
  }).toList();

  late final List<OperationTrip> _todayOperating = todayTrips
      .where((t) => t.status != OperationTripStatus.cancelled)
      .toList();

  int get tripsToday => _todayOperating.length;
  MetricTrend? get tripsTrend => _dayOverDay(tripsWeek);

  int get tripsRunningNow => _todayOperating
      .where((t) => t.status == OperationTripStatus.inProgress)
      .length;

  int get tripsUpcomingToday => _todayOperating
      .where(
        (t) =>
            t.status != OperationTripStatus.inProgress &&
            t.status != OperationTripStatus.completed &&
            (t.scheduledAt?.isAfter(generatedAt) ?? false),
      )
      .length;

  int get tripsCompletedToday => _todayOperating
      .where((t) => t.status == OperationTripStatus.completed)
      .length;

  int get tripsCancelledToday => todayTrips
      .where((t) => t.status == OperationTripStatus.cancelled)
      .length;

  /// Today's trips past their departure time that have not started.
  ///
  /// Derived from the schedule rather than from live tracking, so the figure is
  /// the same whether or not the office is licensed for the Live Ops module.
  late final List<OperationTrip> delayedTrips = _todayOperating.where((t) {
    final at = t.scheduledAt;
    if (at == null || !at.isBefore(generatedAt)) return false;
    return t.status == OperationTripStatus.scheduled ||
        t.status == OperationTripStatus.openForBooking ||
        t.status == OperationTripStatus.boarding;
  }).toList();

  double get occupancyToday => occupancyWeek.last.value;
  MetricTrend? get occupancyTrend => _dayOverDay(occupancyWeek);

  /// Open trips nobody is driving — the queue Home raises too, counted the
  /// same way so the two pages never disagree.
  late final List<OperationTrip> tripsWithoutCaptain = trips.where((trip) {
    if (trip.status == OperationTripStatus.cancelled ||
        trip.status == OperationTripStatus.completed) {
      return false;
    }
    final at = trip.scheduledAt;
    if (at == null || at.isBefore(_today)) return false;
    return trip.driver.trim().isEmpty;
  }).toList();

  late final List<OperationTrip> staleTrips = trips
      .where((trip) => trip.isStaleBooking(now: generatedAt))
      .toList();

  /// How full each route ran over [windowDays], best first.
  ///
  /// Cancelled trips and zero-capacity trips are excluded: the first was never
  /// going to fill, and the second is how a "0% route" that never existed ends
  /// up on the board.
  List<RouteStanding> routeStandings({int limit = 5, int windowDays = 30}) {
    final from = _today.subtract(Duration(days: windowDays));
    final booked = <String, int>{};
    final capacity = <String, int>{};
    final count = <String, int>{};

    for (final trip in trips) {
      if (trip.status == OperationTripStatus.cancelled) continue;
      final at = trip.scheduledAt;
      if (at == null || at.isBefore(from)) continue;
      final route = trip.route.trim();
      if (route.isEmpty || trip.capacity == 0) continue;
      booked[route] = (booked[route] ?? 0) + trip.bookedSeats;
      capacity[route] = (capacity[route] ?? 0) + trip.capacity;
      count[route] = (count[route] ?? 0) + 1;
    }

    final rows =
        [
          for (final route in capacity.keys)
            RouteStanding(
              route: route,
              bookedSeats: booked[route] ?? 0,
              capacity: capacity[route] ?? 0,
              trips: count[route] ?? 0,
            ),
        ]..sort((a, b) {
          final byRate = b.occupancyRate.compareTo(a.occupancyRate);
          return byRate != 0
              ? byRate
              : b.bookedSeats.compareTo(a.bookedSeats);
        });
    return rows.take(limit).toList();
  }

  FleetSummary? get fleetSummary => fleet?.summary;

  int get activeDrivers =>
      fleet?.drivers
          .where((d) => d.status == FleetDriverStatus.active)
          .length ??
      0;

  int get activeVehicles =>
      fleet?.vehicles
          .where((v) => v.status == FleetVehicleStatus.active)
          .length ??
      0;

  int get vehiclesInMaintenance =>
      fleet?.vehicles
          .where((v) => v.status == FleetVehicleStatus.maintenance)
          .length ??
      0;

  /// Drivers actually rostered today — distinct drivers on a non-cancelled trip
  /// scheduled for today, not "everyone on the payroll".
  late final int driversOnDuty = _todayOperating
      .map((t) => t.driverId.trim())
      .where((id) => id.isNotEmpty)
      .toSet()
      .length;

  late final int vehiclesOnRoad = _todayOperating
      .map((t) => t.vehicleId.trim())
      .where((id) => id.isNotEmpty)
      .toSet()
      .length;

  /// Share of the active fleet carrying passengers today. Null when there is no
  /// active fleet to measure against.
  double? get fleetUtilisation {
    if (activeVehicles == 0) return null;
    return vehiclesOnRoad / activeVehicles;
  }

  int get openIncidents => liveOps?.openIncidentCount ?? 0;

  static const _unpaidStatuses = {
    PaymentStatus.pending,
    PaymentStatus.submitted,
    PaymentStatus.underReview,
  };

  /// Fare collected in the window — approved payments, dated by `created_at`.
  double collected({int days = 30}) => revenueSeries(
    days: days,
  ).fold<double>(0, (sum, day) => sum + day.value);

  /// Fare sold but not yet collected: still-live bookings whose payment has not
  /// been approved. Rejected, refunded, failed and cancelled payments are not
  /// outstanding — nobody is waiting for that money.
  late final double outstanding = bookings
      .where(
        (b) =>
            b.status != BookingStatus.cancelled &&
            _unpaidStatuses.contains(b.paymentStatus),
      )
      .fold<double>(0, (sum, b) => sum + b.paymentAmount);

  late final List<BookingPaymentVerification> pendingPaymentReviews =
      paymentVerifications
          .where((p) => p.status == BookingVerificationStatus.pending)
          .toList();

  late final List<RefundRequest> pendingRefunds = refundRequests
      .where((r) => r.status == RefundStatus.pending)
      .toList();

  double get pendingRefundAmount =>
      pendingRefunds.fold<double>(0, (sum, r) => sum + r.amount);

  /// Refunds **settled** in the window, whatever their destination. Read from
  /// the wallet position, which sources them from `refund_requests` — a refund
  /// paid to InstaPay never posts a wallet row, so a ledger-derived total would
  /// omit exactly the amounts most likely to be disputed.
  double refundsSettled({int days = 30}) {
    final from = _today.subtract(Duration(days: days - 1));
    return (wallet?.refunds ?? const <SettledRefund>[])
        .where((r) => !r.settledAt.isBefore(from))
        .fold<double>(0, (sum, r) => sum + r.amount);
  }

  /// Money given away as incentive in the window — cashback and manual credits,
  /// net of clawbacks. A liability created with no cash received, which is why
  /// Finance reports it beside revenue rather than inside it.
  double promotionalCost({int days = 30}) {
    final from = _today.subtract(Duration(days: days - 1));
    return (wallet?.movements ?? const <WalletMovement>[])
        .where((m) => m.isPromotional && !m.date.isBefore(from))
        .fold<double>(0, (sum, m) => sum + m.amount);
  }

  /// Σ wallet balances right now — money held and owed back as service.
  double get walletLiability => wallet?.currentLiability ?? 0;

  /// What the office sold in the window, net of what it handed back.
  ///
  /// This is `FinanceMoneyStatements.revenue`'s definition (`soldFare −
  /// refundsTotal`) evaluated over a rolling window. It is a *summary* of the
  /// Finance module's accrual line, not a second accounting model: the full
  /// three-statement view with its control identity stays in Finance, and the
  /// panel that shows this links there.
  double netRevenue({int days = 30}) =>
      collected(days: days) - refundsSettled(days: days);

  /// Net revenue after the office pays for its own incentives — Finance's
  /// `contributionAfterIncentives`, reported as a second line and never as
  /// *the* revenue figure.
  double contribution({int days = 30}) =>
      netRevenue(days: days) - promotionalCost(days: days);

  /// Share of everything invoiced in the window that actually arrived.
  double? collectionRate({int days = 30}) {
    final from = _today.subtract(Duration(days: days - 1));
    var billed = 0.0;
    var received = 0.0;
    for (final booking in bookings) {
      if (booking.status == BookingStatus.cancelled) continue;
      if (_startOfDay(booking.createdAt).isBefore(from)) continue;
      final isPaid = booking.paymentStatus == PaymentStatus.approved;
      if (!isPaid && !_unpaidStatuses.contains(booking.paymentStatus)) continue;
      billed += booking.paymentAmount;
      if (isPaid) received += booking.paymentAmount;
    }
    if (billed <= 0) return null;
    return received / billed;
  }

  /// Share of bookings taken in the window that were later cancelled.
  double? cancellationRate({int days = 30}) {
    final from = _today.subtract(Duration(days: days - 1));
    var total = 0;
    var cancelled = 0;
    for (final booking in bookings) {
      if (_startOfDay(booking.createdAt).isBefore(from)) continue;
      total += 1;
      if (booking.status == BookingStatus.cancelled) cancelled += 1;
    }
    if (total == 0) return null;
    return cancelled / total;
  }

  late final Map<String, List<OperationBooking>> _byCustomer = () {
    final map = <String, List<OperationBooking>>{};
    for (final booking in bookings) {
      final id = booking.clientId.trim();
      if (id.isEmpty) continue;
      map.putIfAbsent(id, () => []).add(booking);
    }
    return map;
  }();

  int get totalCustomers => _byCustomer.length;

  /// Customers who booked at least once in the last [days] days.
  Set<String> activeCustomerIds({int days = 30}) {
    final from = _today.subtract(Duration(days: days - 1));
    return {
      for (final entry in _byCustomer.entries)
        if (entry.value.any((b) => !_startOfDay(b.createdAt).isBefore(from)))
          entry.key,
    };
  }

  /// Customers whose **first ever** booking falls inside the window.
  Set<String> newCustomerIds({int days = 30}) {
    final from = _today.subtract(Duration(days: days - 1));
    return {
      for (final entry in _byCustomer.entries)
        if (!entry.value
            .map((b) => b.createdAt)
            .reduce((a, b) => a.isBefore(b) ? a : b)
            .isBefore(from))
          entry.key,
    };
  }

  /// Active customers who had already booked before the window opened.
  Set<String> returningCustomerIds({int days = 30}) =>
      activeCustomerIds(days: days).difference(newCustomerIds(days: days));

  /// Customers with history who have gone quiet for the whole window.
  int inactiveCustomers({int days = 30}) =>
      totalCustomers - activeCustomerIds(days: days).length;

  /// Share of the window's active customers who are returning rather than new.
  /// Null when nobody booked at all — 0% would imply they all churned.
  double? retentionRate({int days = 30}) {
    final active = activeCustomerIds(days: days);
    if (active.isEmpty) return null;
    return returningCustomerIds(days: days).length / active.length;
  }

  /// The account that paid the office the most over the window.
  ///
  /// Named from the latest booking's passenger, which is the only name on the
  /// row — for a household account that is the person who travelled most
  /// recently, not necessarily the account holder.
  TopCustomer? topCustomer({int days = 30}) {
    final from = _today.subtract(Duration(days: days - 1));
    TopCustomer? best;
    for (final entry in _byCustomer.entries) {
      final window = entry.value
          .where(
            (b) =>
                b.paymentStatus == PaymentStatus.approved &&
                !_startOfDay(b.createdAt).isBefore(from),
          )
          .toList();
      if (window.isEmpty) continue;
      final spend = window.fold<double>(0, (sum, b) => sum + b.paymentAmount);
      if (best != null && spend <= best.spend) continue;
      final latest = window.reduce(
        (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
      );
      best = TopCustomer(
        clientId: entry.key,
        name: latest.passengerName,
        spend: spend,
        bookings: window.length,
      );
    }
    return best;
  }

  /// Mean of the driver, vehicle and route ratings left in the window, on the
  /// original 1–5 scale. Null when nobody rated anything.
  double? satisfaction({int days = 30}) {
    final from = _today.subtract(Duration(days: days - 1));
    return _averageRating(
      reviews.where((r) => !_startOfDay(r.createdAt).isBefore(from)),
    );
  }

  /// The same reading over the window before it, so the tile can show movement.
  MetricTrend? satisfactionTrend({int days = 30}) {
    final currentFrom = _today.subtract(Duration(days: days - 1));
    final previousFrom = currentFrom.subtract(Duration(days: days));
    final current = satisfaction(days: days);
    final previous = _averageRating(
      reviews.where((r) {
        final day = _startOfDay(r.createdAt);
        return !day.isBefore(previousFrom) && day.isBefore(currentFrom);
      }),
    );
    if (current == null || previous == null) return null;
    return MetricTrend(
      current: current,
      previous: previous,
      previousLabel: 'الفترة السابقة',
    );
  }

  double? _averageRating(Iterable<TripReviewEntry> entries) {
    var sum = 0;
    var count = 0;
    for (final review in entries) {
      sum += review.driverRating + review.vehicleRating + review.routeRating;
      count += 3;
    }
    return count == 0 ? null : sum / count;
  }

  /// The seven graded readings, problems first.
  ///
  /// Thresholds are stated in each signal's `detail` rather than buried here,
  /// because a badge an owner cannot interrogate is a badge they learn to
  /// ignore.
  late final List<BusinessHealthSignal> healthSignals = () {
    final signals = <BusinessHealthSignal>[
      _revenueHealth(),
      _occupancyHealth(),
      _cancellationHealth(),
      _delayedHealth(),
      _refundHealth(),
      _fleetHealth(),
      _collectionHealth(),
    ];
    signals.sort((a, b) => b.status.index.compareTo(a.status.index));
    return signals;
  }();

  BusinessHealthSignal _revenueHealth() {
    final trend = revenueWeekTrend;
    if (trend == null || (trend.current == 0 && trend.previous == 0)) {
      return const BusinessHealthSignal(
        metric: BusinessHealthMetric.revenueTrend,
        status: BusinessHealthStatus.unknown,
        reading: '—',
        detail: 'يحتاج أسبوعين من الحجوزات للمقارنة',
      );
    }
    final ratio = trend.changeRatio;
    final status = switch (ratio) {
      null => trend.current > 0
          ? BusinessHealthStatus.healthy
          : BusinessHealthStatus.critical,
      final r when r >= 0 => BusinessHealthStatus.healthy,
      final r when r > -0.15 => BusinessHealthStatus.warning,
      _ => BusinessHealthStatus.critical,
    };
    return BusinessHealthSignal(
      metric: BusinessHealthMetric.revenueTrend,
      status: status,
      reading: ratio == null
          ? '${trend.current.round()} ج.م'
          : '${(ratio * 100).round()}%',
      detail:
          'آخر ٧ أيام ${trend.current.round()} ج.م مقابل ${trend.previous.round()} ج.م',
    );
  }

  BusinessHealthSignal _occupancyHealth() {
    if (_todayOperating.isEmpty) {
      return const BusinessHealthSignal(
        metric: BusinessHealthMetric.occupancy,
        status: BusinessHealthStatus.unknown,
        reading: '—',
        detail: 'لا توجد رحلات مجدولة اليوم',
      );
    }
    final rate = occupancyToday;
    final status = rate >= 0.70
        ? BusinessHealthStatus.healthy
        : rate >= 0.50
        ? BusinessHealthStatus.warning
        : BusinessHealthStatus.critical;
    return BusinessHealthSignal(
      metric: BusinessHealthMetric.occupancy,
      status: status,
      reading: '${(rate * 100).round()}%',
      detail: 'الهدف ٧٠٪ فأكثر · عبر ${_todayOperating.length} رحلة اليوم',
    );
  }

  BusinessHealthSignal _cancellationHealth() {
    final rate = cancellationRate();
    if (rate == null) {
      return const BusinessHealthSignal(
        metric: BusinessHealthMetric.cancellationRate,
        status: BusinessHealthStatus.unknown,
        reading: '—',
        detail: 'لا حجوزات في آخر ٣٠ يوم',
      );
    }
    final status = rate < 0.05
        ? BusinessHealthStatus.healthy
        : rate < 0.10
        ? BusinessHealthStatus.warning
        : BusinessHealthStatus.critical;
    return BusinessHealthSignal(
      metric: BusinessHealthMetric.cancellationRate,
      status: status,
      reading: '${(rate * 100).round()}%',
      detail: 'المقبول أقل من ٥٪ من حجوزات آخر ٣٠ يوم',
    );
  }

  BusinessHealthSignal _delayedHealth() {
    final count = delayedTrips.length;
    final status = count == 0
        ? BusinessHealthStatus.healthy
        : count <= 2
        ? BusinessHealthStatus.warning
        : BusinessHealthStatus.critical;
    return BusinessHealthSignal(
      metric: BusinessHealthMetric.delayedTrips,
      status: status,
      reading: '$count',
      detail: count == 0
          ? 'كل رحلات اليوم في موعدها'
          : 'فات موعد القيام ولم تبدأ بعد',
    );
  }

  BusinessHealthSignal _refundHealth() {
    if (!has(BusinessDataSource.refunds)) {
      return const BusinessHealthSignal(
        metric: BusinessHealthMetric.openRefunds,
        status: BusinessHealthStatus.unknown,
        reading: '—',
        detail: 'تعذّر تحميل طلبات الاسترداد',
      );
    }
    final count = pendingRefunds.length;
    final status = count == 0
        ? BusinessHealthStatus.healthy
        : count <= 3
        ? BusinessHealthStatus.warning
        : BusinessHealthStatus.critical;
    return BusinessHealthSignal(
      metric: BusinessHealthMetric.openRefunds,
      status: status,
      reading: '$count',
      detail: count == 0
          ? 'لا طلبات استرداد معلّقة'
          : 'بقيمة ${pendingRefundAmount.round()} ج.م بانتظار قرارك',
    );
  }

  BusinessHealthSignal _fleetHealth() {
    final utilisation = fleetUtilisation;
    if (utilisation == null) {
      return const BusinessHealthSignal(
        metric: BusinessHealthMetric.fleetUtilisation,
        status: BusinessHealthStatus.unknown,
        reading: '—',
        detail: 'لا توجد مركبات نشطة مسجّلة',
      );
    }
    final status = utilisation >= 0.60
        ? BusinessHealthStatus.healthy
        : utilisation >= 0.35
        ? BusinessHealthStatus.warning
        : BusinessHealthStatus.critical;
    return BusinessHealthSignal(
      metric: BusinessHealthMetric.fleetUtilisation,
      status: status,
      reading: '${(utilisation * 100).round()}%',
      detail: '$vehiclesOnRoad من $activeVehicles مركبة على الطريق اليوم',
    );
  }

  BusinessHealthSignal _collectionHealth() {
    final rate = collectionRate();
    if (rate == null) {
      return const BusinessHealthSignal(
        metric: BusinessHealthMetric.collectionHealth,
        status: BusinessHealthStatus.unknown,
        reading: '—',
        detail: 'لا مبالغ مستحقة في آخر ٣٠ يوم',
      );
    }
    final status = rate >= 0.90
        ? BusinessHealthStatus.healthy
        : rate >= 0.75
        ? BusinessHealthStatus.warning
        : BusinessHealthStatus.critical;
    return BusinessHealthSignal(
      metric: BusinessHealthMetric.collectionHealth,
      status: status,
      reading: '${(rate * 100).round()}%',
      detail: 'من قيمة حجوزات آخر ٣٠ يوم · ${outstanding.round()} ج.م لم تُحصّل',
    );
  }

  /// What the numbers *mean*, in sentences, most urgent first.
  ///
  /// Every item is measured — the window and the figures are quoted in each
  /// one — and every rule below refuses to speak when its evidence is thin
  /// (a route with two trips, a weekday with one sample). Silence is the
  /// correct output for a quiet week; a page of confident noise is not.
  late final List<BusinessInsight> insights = () {
    final items = <BusinessInsight>[
      ...?_routeInsights(),
      ...?_weekdayInsight(),
      ...?_revenueInsight(),
      ...?_refundInsight(),
      ...?_driverInsight(),
      ...?_retentionInsight(),
    ];
    items.sort(BusinessInsight.compare);
    return items;
  }();

  List<BusinessInsight>? _routeInsights() {
    final standings = routeStandings(limit: 20);
    final measurable = standings.where((r) => r.trips >= 3).toList();
    if (measurable.isEmpty) return null;

    final items = <BusinessInsight>[];
    final best = measurable.first;
    if (best.occupancyRate >= 0.85) {
      items.add(
        BusinessInsight(
          id: 'route.best.${best.route}',
          kind: InsightKind.routePerformance,
          severity: InsightSeverity.positive,
          title:
              'خط ${best.route} وصل إلى ${(best.occupancyRate * 100).round()}٪ إشغال',
          detail:
              '${best.bookedSeats} مقعد من ${best.capacity} عبر ${best.trips} رحلة في آخر ٣٠ يوم. زيادة عدد الرحلات على هذا الخط هي أقرب فرصة نمو.',
          action: const InsightAction(label: 'خطّط رحلة', route: '/trips'),
        ),
      );
    }

    final worst = measurable.last;
    if (worst.route != best.route && worst.occupancyRate < 0.40) {
      items.add(
        BusinessInsight(
          id: 'route.worst.${worst.route}',
          kind: InsightKind.occupancyOpportunity,
          severity: InsightSeverity.warning,
          title:
              'خط ${worst.route} لا يتجاوز ${(worst.occupancyRate * 100).round()}٪ إشغال',
          detail:
              '${worst.bookedSeats} مقعد من ${worst.capacity} عبر ${worst.trips} رحلة. راجع المواعيد أو قلّل عدد الرحلات على الخط.',
          action: const InsightAction(label: 'افتح الرحلات', route: '/trips'),
        ),
      );
    }
    return items.isEmpty ? null : items;
  }

  /// The weekday that sells best, over eight weeks of taken bookings.
  ///
  /// Needs at least three samples per weekday before it will name one — with
  /// fewer, "الجمعة هو الأقوى" is one busy Friday wearing a trend's clothes.
  List<BusinessInsight>? _weekdayInsight() {
    final series = revenueSeries(days: 56);
    final totals = <int, double>{};
    final counts = <int, int>{};
    for (final point in series) {
      totals[point.day.weekday] = (totals[point.day.weekday] ?? 0) + point.value;
      counts[point.day.weekday] = (counts[point.day.weekday] ?? 0) + 1;
    }
    final eligible = totals.keys.where((day) => (counts[day] ?? 0) >= 3);
    if (eligible.length < 4) return null;

    final averages = {
      for (final day in eligible) day: totals[day]! / counts[day]!,
    };
    final overall =
        averages.values.fold<double>(0, (a, b) => a + b) / averages.length;
    if (overall <= 0) return null;

    final bestDay = averages.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    if (bestDay.value < overall * 1.25) return null;

    return [
      BusinessInsight(
        id: 'weekday.${bestDay.key}',
        kind: InsightKind.demandPattern,
        severity: InsightSeverity.informational,
        title: '${_weekdayName(bestDay.key)} هو أقوى أيام الأسبوع لديك',
        detail:
            'متوسط ${bestDay.value.round()} ج.م مقابل ${overall.round()} ج.م لبقية الأيام، على مدى ٨ أسابيع. وسّع الطاقة المعروضة في هذا اليوم أولاً.',
        action: const InsightAction(label: 'افتح التقارير', route: '/reports'),
      ),
    ];
  }

  List<BusinessInsight>? _revenueInsight() {
    final trend = revenueWeekTrend;
    final ratio = trend?.changeRatio;
    if (trend == null || ratio == null || ratio.abs() < 0.10) return null;

    final up = ratio > 0;
    return [
      BusinessInsight(
        id: 'revenue.week',
        kind: InsightKind.revenueComparison,
        severity: up ? InsightSeverity.positive : InsightSeverity.warning,
        title: up
            ? 'إيراد الحجوزات ارتفع ${(ratio * 100).round()}٪ هذا الأسبوع'
            : 'إيراد الحجوزات انخفض ${(ratio.abs() * 100).round()}٪ هذا الأسبوع',
        detail:
            '${trend.current.round()} ج.م في آخر ٧ أيام مقابل ${trend.previous.round()} ج.م في الأسبوع السابق، محسوبة من المدفوعات المقبولة.',
        action: const InsightAction(label: 'افتح المالية', route: '/payments'),
      ),
    ];
  }

  List<BusinessInsight>? _refundInsight() {
    if (!has(BusinessDataSource.refunds)) return null;
    final thisWeek = _refundsBetween(7, 0);
    final lastWeek = _refundsBetween(14, 7);
    if (thisWeek < 3 || thisWeek <= lastWeek) return null;
    if (lastWeek > 0 && thisWeek < lastWeek * 1.25) return null;

    return [
      BusinessInsight(
        id: 'refunds.week',
        kind: InsightKind.refundTrend,
        severity: InsightSeverity.warning,
        title: 'طلبات الاسترداد ارتفعت هذا الأسبوع',
        detail:
            '$thisWeek طلب في آخر ٧ أيام مقابل $lastWeek في الأسبوع السابق. راجع أسباب الاسترداد قبل أن تتحول إلى نمط.',
        action: const InsightAction(
          label: 'افتح محفظة العملاء',
          route: '/wallet',
        ),
      ),
    ];
  }

  int _refundsBetween(int fromDaysAgo, int toDaysAgo) {
    final from = _today.subtract(Duration(days: fromDaysAgo - 1));
    final to = _today.subtract(Duration(days: toDaysAgo));
    return refundRequests
        .where((r) => !r.date.isBefore(from) && r.date.isBefore(to))
        .length;
  }

  /// A driver whose trips are cancelled far more often than the fleet's norm.
  ///
  /// Requires at least five trips for that driver and a rate at least double
  /// the fleet average, so a new captain with one bad day is never named.
  List<BusinessInsight>? _driverInsight() {
    final from = _today.subtract(const Duration(days: 30));
    final total = <String, int>{};
    final cancelled = <String, int>{};
    for (final trip in trips) {
      final at = trip.scheduledAt;
      if (at == null || at.isBefore(from)) continue;
      final driver = trip.driver.trim();
      if (driver.isEmpty) continue;
      total[driver] = (total[driver] ?? 0) + 1;
      if (trip.status == OperationTripStatus.cancelled) {
        cancelled[driver] = (cancelled[driver] ?? 0) + 1;
      }
    }
    final fleetTotal = total.values.fold<int>(0, (a, b) => a + b);
    final fleetCancelled = cancelled.values.fold<int>(0, (a, b) => a + b);
    if (fleetTotal < 10 || fleetCancelled == 0) return null;
    final fleetRate = fleetCancelled / fleetTotal;

    String? worst;
    var worstRate = 0.0;
    for (final entry in total.entries) {
      if (entry.value < 5) continue;
      final rate = (cancelled[entry.key] ?? 0) / entry.value;
      if (rate > worstRate) {
        worst = entry.key;
        worstRate = rate;
      }
    }
    if (worst == null || worstRate < fleetRate * 2 || worstRate < 0.20) {
      return null;
    }

    return [
      BusinessInsight(
        id: 'driver.$worst',
        kind: InsightKind.driverPerformance,
        severity: InsightSeverity.warning,
        title: 'السائق $worst تجاوز معدل الإلغاء المعتاد',
        detail:
            '${(worstRate * 100).round()}٪ من رحلاته أُلغيت في آخر ٣٠ يوم، مقابل ${(fleetRate * 100).round()}٪ لبقية الأسطول (${cancelled[worst]} من ${total[worst]} رحلة).',
        action: const InsightAction(label: 'افتح الأسطول', route: '/fleet'),
      ),
    ];
  }

  List<BusinessInsight>? _retentionInsight() {
    final rate = retentionRate();
    final active = activeCustomerIds().length;
    if (rate == null || active < 10) return null;

    final returning = returningCustomerIds().length;
    final healthy = rate >= 0.40;
    return [
      BusinessInsight(
        id: 'retention.30',
        kind: InsightKind.customerRetention,
        severity: healthy
            ? InsightSeverity.positive
            : InsightSeverity.informational,
        title: healthy
            ? '${(rate * 100).round()}٪ من عملاء الشهر عملاء عائدون'
            : 'أغلب عملاء الشهر يحجزون لأول مرة',
        detail:
            '$returning عميلاً عائداً من $active عميل نشط في آخر ٣٠ يوم. ${healthy ? 'قاعدة العملاء تتماسك.' : 'برنامج كاش باك أو باقة متكررة قد يرفع نسبة العودة.'}',
        action: const InsightAction(
          label: 'افتح محفظة العملاء',
          route: '/wallet',
        ),
      ),
    ];
  }

  /// Bookings still live on a trip that was cancelled.
  ///
  /// The passenger holds a seat on a bus that will not run and nothing else on
  /// the console pairs the two facts — which is exactly why it belongs on the
  /// owner's list rather than in a report.
  late final List<OperationBooking> bookingConflicts = () {
    final cancelledTrips = {
      for (final trip in trips)
        if (trip.status == OperationTripStatus.cancelled) trip.id,
    };
    if (cancelledTrips.isEmpty) return <OperationBooking>[];
    return bookings
        .where(
          (b) =>
              cancelledTrips.contains(b.tripDetails.tripId) &&
              b.status != BookingStatus.cancelled,
        )
        .toList();
  }();

  late final List<SupportTicket> urgentComplaints = tickets
      .where(
        (t) =>
            t.status != TicketStatus.resolved &&
            t.status != TicketStatus.closed &&
            t.status != TicketStatus.rejected &&
            (t.priority == TicketPriority.urgent ||
                t.priority == TicketPriority.high),
      )
      .toList();

  late final List<BusinessAttentionItem> attentionItems = () {
    final cancellation = cancellationRate() ?? 0;
    final items =
        <BusinessAttentionItem>[
          BusinessAttentionItem(
            kind: BusinessAttentionKind.paymentsAwaitingReview,
            count: pendingPaymentReviews.length,
          ),
          BusinessAttentionItem(
            kind: BusinessAttentionKind.refundRequests,
            count: pendingRefunds.length,
            note: pendingRefunds.isEmpty
                ? null
                : '${pendingRefundAmount.round()} ج.م',
          ),
          BusinessAttentionItem(
            kind: BusinessAttentionKind.tripsWithoutCaptain,
            count: tripsWithoutCaptain.length,
          ),
          BusinessAttentionItem(
            kind: BusinessAttentionKind.bookingConflicts,
            count: bookingConflicts.length,
          ),
          BusinessAttentionItem(
            kind: BusinessAttentionKind.staleTrips,
            count: staleTrips.length,
          ),
          
          BusinessAttentionItem(
            kind: BusinessAttentionKind.highCancellationRate,
            count: cancellation >= 0.10 ? (cancellation * 100).round() : 0,
            note: '${(cancellation * 100).round()}% من حجوزات ٣٠ يوم',
          ),
          BusinessAttentionItem(
            kind: BusinessAttentionKind.vehiclesInMaintenance,
            count: vehiclesInMaintenance,
          ),
          BusinessAttentionItem(
            kind: BusinessAttentionKind.expiringDocuments,
            count: fleetSummary?.documentsNeedFollowUpCount ?? 0,
          ),
          BusinessAttentionItem(
            kind: BusinessAttentionKind.urgentComplaints,
            count: urgentComplaints.length,
          ),
          BusinessAttentionItem(
            kind: BusinessAttentionKind.captainRequests,
            count: captainRequests.where((r) => r.isPending).length,
          ),
          BusinessAttentionItem(
            kind: BusinessAttentionKind.subscriptionsAwaitingPayment,
            count: subscriptions
                .where((s) => s.status == SubscriptionStatus.pendingPayment)
                .length,
          ),
        ].where((item) => item.count > 0).toList()..sort((a, b) {
          final bySeverity = b.kind.severity.index.compareTo(
            a.kind.severity.index,
          );
          return bySeverity != 0 ? bySeverity : b.count.compareTo(a.count);
        });
    return items;
  }();

  static DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _weekdayName(int weekday) => switch (weekday) {
    DateTime.saturday => 'السبت',
    DateTime.sunday => 'الأحد',
    DateTime.monday => 'الاثنين',
    DateTime.tuesday => 'الثلاثاء',
    DateTime.wednesday => 'الأربعاء',
    DateTime.thursday => 'الخميس',
    _ => 'الجمعة',
  };
}

/// Mutable accumulator behind [BusinessOverview._series]. Three fields rather
/// than three passes: occupancy needs a numerator and a denominator, money
/// needs a total, counts need a tally.
class _DayBucket {
  double total = 0;
  int count = 0;
  int capacity = 0;
}
