import 'platform_office.dart';

/// What the platform is doing, as opposed to what it contains.
///
/// [PlatformOffice] answers "which offices exist and how are they configured".
/// This answers "which of them are actually trading" — a question none of the
/// lifetime counts on the office card can reach, because a lifetime count cannot
/// distinguish an office that ran eight trips yesterday from one that ran eight
/// trips last spring and was abandoned.
///
/// Every number here is scoped to [windowDays] unless its name says otherwise,
/// and every one of them is an aggregate: the platform sees magnitudes, never
/// the booking rows, receipts or passengers behind them.
class PlatformAnalytics {
  const PlatformAnalytics({
    required this.windowDays,
    required this.totals,
    required this.trend,
    required this.offices,
    this.generatedAt,
  });

  final int windowDays;
  final PlatformTotals totals;

  /// Platform-wide demand, one point per day, oldest first. Quiet days are
  /// present as zeros — the server generates the calendar rather than grouping
  /// only the days that happen to have rows.
  final List<PlatformTrendPoint> trend;

  /// Per-office metrics, keyed by office id so the list screen can attach them
  /// to offices it already holds without matching by name or index.
  final Map<String, PlatformOfficeMetrics> offices;

  final DateTime? generatedAt;

  static const empty = PlatformAnalytics(
    windowDays: 30,
    totals: PlatformTotals(),
    trend: [],
    offices: {},
  );

  PlatformOfficeMetrics? metricsFor(String officeId) => offices[officeId];

  /// Everything demanding the platform admin's attention right now, worst first.
  ///
  /// Built by walking the offices the caller passes in rather than the metrics
  /// map alone, because half the checks need the office's configuration next to
  /// its activity: "listed with nothing to sell" is only alarming for an office
  /// that is actually listed, and an office with no bookings is a problem only
  /// once it is old enough that it should have had some.
  List<OfficeAttention> attentionFor(List<PlatformOffice> allOffices) {
    final items = <OfficeAttention>[
      for (final office in allOffices)
        ...?_flagsFor(office, offices[office.id]),
    ];
    items.sort((a, b) {
      final bySeverity = b.severity.rank.compareTo(a.severity.rank);
      return bySeverity != 0
          ? bySeverity
          : a.officeName.compareTo(b.officeName);
    });
    return items;
  }

  List<OfficeAttention>? _flagsFor(
    PlatformOffice office,
    PlatformOfficeMetrics? metrics,
  ) {
    
    if (metrics == null) return null;
    final flags = <OfficeAttention>[];

    void add(AttentionSeverity severity, String title, String detail) {
      flags.add(
        OfficeAttention(
          officeId: office.id,
          officeName: office.name,
          severity: severity,
          title: title,
          detail: detail,
        ),
      );
    }

    if (metrics.activeAdmins == 0) {
      add(
        AttentionSeverity.critical,
        'لا يوجد مسؤول نشط',
        'لا يستطيع أحد تسجيل الدخول إلى لوحة تحكم هذا المكتب.',
      );
    }

    if (office.isListed && metrics.upcomingTrips == 0) {
      add(
        AttentionSeverity.critical,
        'معروض بدون رحلات قادمة',
        'يظهر المكتب للعملاء لكن لا توجد رحلة واحدة متاحة للحجز.',
      );
    }

    if (metrics.paymentsAwaitingReview > 0) {
      add(
        AttentionSeverity.warning,
        'مدفوعات بانتظار المراجعة',
        '${metrics.paymentsAwaitingReview} عملية دفع '
            '(${metrics.awaitingAmountLabel}) لم يبتّ فيها أحد.',
      );
    }

    if (metrics.staleTrips > 0) {
      add(
        AttentionSeverity.warning,
        'رحلات فات موعدها',
        '${metrics.staleTrips} رحلة مضى موعدها وما زالت مفتوحة للحجز.',
      );
    }

    if (metrics.isIdle) {
      final days = metrics.daysSinceLastBooking;
      add(
        AttentionSeverity.warning,
        'توقف عن النشاط',
        days == null
            ? 'لا توجد حجوزات خلال آخر $windowDays يوم.'
            : 'آخر حجز منذ $days يوم.',
      );
    }

    if (metrics.cancellationRate >= 0.3 && metrics.totalBookings >= 5) {
      add(
        AttentionSeverity.warning,
        'نسبة إلغاء مرتفعة',
        'أُلغي ${metrics.cancellationRateLabel} من حجوزات هذا المكتب.',
      );
    }

    if (metrics.reviewsTotal >= 3 &&
        metrics.averageRating != null &&
        metrics.averageRating! < 3) {
      add(
        AttentionSeverity.warning,
        'تقييم منخفض',
        'متوسط تقييم المكتب ${metrics.averageRating!.toStringAsFixed(1)} '
            'من ${metrics.reviewsTotal} تقييم.',
      );
    }

    final age = office.createdAt == null
        ? null
        : DateTime.now().difference(office.createdAt!).inDays;
    if (metrics.totalBookings == 0 && age != null && age >= 7) {
      add(
        AttentionSeverity.info,
        'لم يبدأ العمل بعد',
        'مضى $age يوم على إنشاء المكتب دون أي حجز.',
      );
    }

    if (metrics.pendingCaptainRequests > 0) {
      add(
        AttentionSeverity.info,
        'طلبات كباتن معلقة',
        '${metrics.pendingCaptainRequests} طلب انضمام بانتظار المراجعة.',
      );
    }

    if (metrics.openTickets > 0) {
      add(
        AttentionSeverity.info,
        'تذاكر دعم مفتوحة',
        '${metrics.openTickets} تذكرة لم تُغلق بعد.',
      );
    }

    return flags;
  }
}

/// Platform-wide roll-up. The same aggregation the per-office rows come from,
/// computed server-side in the same snapshot so the header can never disagree
/// with the list beneath it.
class PlatformTotals {
  const PlatformTotals({
    this.offices = 0,
    this.active = 0,
    this.paused = 0,
    this.suspended = 0,
    this.archived = 0,
    this.listed = 0,
    this.draft = 0,
    this.unlisted = 0,
    this.trading = 0,
    this.idle = 0,
    this.neverTraded = 0,
    this.onboardedInWindow = 0,
    this.withoutAdmin = 0,
    this.listedWithoutTrips = 0,
    this.tripsTotal = 0,
    this.tripsRecent = 0,
    this.tripsUpcoming = 0,
    this.tripsStale = 0,
    this.bookingsTotal = 0,
    this.bookingsRecent = 0,
    this.revenueTotal = 0,
    this.revenueRecent = 0,
    this.paymentsAwaitingReview = 0,
    this.paymentsAwaitingAmount = 0,
    this.ticketsOpen = 0,
    this.captainRequestsPending = 0,
    this.seatsOffered = 0,
    this.seatsSold = 0,
  });

  final int offices;
  final int active;
  final int paused;
  final int suspended;
  final int archived;
  final int listed;
  final int draft;
  final int unlisted;

  /// Offices with at least one booking inside the window.
  final int trading;

  /// Offices that have traded before but not inside the window.
  final int idle;

  /// Offices that have never taken a booking at all.
  final int neverTraded;

  final int onboardedInWindow;

  /// Offices with no active `dashboard_admin` — nobody can sign in to them.
  final int withoutAdmin;

  /// Listed offices with no upcoming trip: marketplace dead ends.
  final int listedWithoutTrips;

  final int tripsTotal;
  final int tripsRecent;
  final int tripsUpcoming;
  final int tripsStale;
  final int bookingsTotal;
  final int bookingsRecent;

  /// Approved payments only. Money committed but not yet reviewed is in
  /// [paymentsAwaitingAmount], never here.
  final double revenueTotal;
  final double revenueRecent;

  final int paymentsAwaitingReview;
  final double paymentsAwaitingAmount;
  final int ticketsOpen;
  final int captainRequestsPending;
  final int seatsOffered;
  final int seatsSold;

  /// Share of offered seats actually taken, across the whole platform. Null
  /// when no seats were offered at all — 0% would claim nobody bought, when in
  /// fact nothing was for sale.
  double? get occupancyRate =>
      seatsOffered == 0 ? null : seatsSold / seatsOffered;

  /// Offices that are active but not on the marketplace: the publish queue.
  int get awaitingListing => active - listed;

  String get revenueRecentLabel => formatMoney(revenueRecent);
  String get revenueTotalLabel => formatMoney(revenueTotal);
  String get awaitingAmountLabel => formatMoney(paymentsAwaitingAmount);
}

/// One day of platform-wide demand.
class PlatformTrendPoint {
  const PlatformTrendPoint({
    required this.day,
    required this.bookings,
    required this.revenue,
  });

  final DateTime day;
  final int bookings;
  final double revenue;
}

/// One office's activity inside the analytics window.
///
/// Deliberately holds no identity beyond [officeId]: the name, status and
/// configuration live on [PlatformOffice], and duplicating them here would let
/// the two disagree after a rename.
class PlatformOfficeMetrics {
  const PlatformOfficeMetrics({
    required this.officeId,
    this.totalTrips = 0,
    this.recentTrips = 0,
    this.upcomingTrips = 0,
    this.staleTrips = 0,
    this.completedTrips = 0,
    this.cancelledTrips = 0,
    this.totalBookings = 0,
    this.recentBookings = 0,
    this.confirmedBookings = 0,
    this.cancelledBookings = 0,
    this.recentCancelledBookings = 0,
    this.revenueTotal = 0,
    this.revenueRecent = 0,
    this.paymentsAwaitingReview = 0,
    this.paymentsAwaitingAmount = 0,
    this.paymentsRejected = 0,
    this.seatsOffered = 0,
    this.seatsSold = 0,
    this.ticketsTotal = 0,
    this.openTickets = 0,
    this.recentTickets = 0,
    this.pendingCaptainRequests = 0,
    this.reviewsTotal = 0,
    this.recentReviews = 0,
    this.activeOperators = 0,
    this.activeAdmins = 0,
    this.averageRating,
    this.lastTripDate,
    this.firstBookingAt,
    this.lastBookingAt,
  });

  final String officeId;

  final int totalTrips;
  final int recentTrips;

  /// Dated today or later and still open for booking — what a passenger can
  /// actually buy.
  final int upcomingTrips;

  /// Past-dated and still open. Never auto-closed by design, so they pile up
  /// until a human is shown them.
  final int staleTrips;

  final int completedTrips;
  final int cancelledTrips;

  final int totalBookings;
  final int recentBookings;
  final int confirmedBookings;
  final int cancelledBookings;
  final int recentCancelledBookings;

  /// Summed from approved booking payments. Not from `operation_trips.revenue`,
  /// which is unmaintained and reads 0 platform-wide.
  final double revenueTotal;
  final double revenueRecent;

  /// Payments a passenger has submitted that the office has neither accepted
  /// nor refused — a workload signal, never counted as revenue.
  final int paymentsAwaitingReview;
  final double paymentsAwaitingAmount;
  final int paymentsRejected;

  final int seatsOffered;
  final int seatsSold;

  final int ticketsTotal;
  final int openTickets;
  final int recentTickets;
  final int pendingCaptainRequests;
  final int reviewsTotal;
  final int recentReviews;
  final int activeOperators;
  final int activeAdmins;

  final double? averageRating;
  final DateTime? lastTripDate;
  final DateTime? firstBookingAt;
  final DateTime? lastBookingAt;

  /// Took a booking inside the window.
  bool get isTrading => recentBookings > 0;

  /// Has traded before, but not inside the window. The churn signal.
  bool get isIdle => recentBookings == 0 && totalBookings > 0;

  bool get hasNeverTraded => totalBookings == 0;

  /// Share of seats offered in the window that were actually sold. Null when
  /// nothing was offered — see [PlatformTotals.occupancyRate].
  double? get occupancyRate =>
      seatsOffered == 0 ? null : seatsSold / seatsOffered;

  /// Lifetime, not windowed: a cancellation habit is a property of how the
  /// office operates, and a 30-day slice of a small office is too few bookings
  /// to say anything about it.
  double get cancellationRate =>
      totalBookings == 0 ? 0 : cancelledBookings / totalBookings;

  int? get daysSinceLastBooking => lastBookingAt == null
      ? null
      : DateTime.now().difference(lastBookingAt!).inDays;

  int? get daysSinceLastTrip => lastTripDate == null
      ? null
      : DateTime.now().difference(lastTripDate!).inDays;

  /// Average money per approved booking — the office's ticket size, which is
  /// what separates a busy cheap office from a quiet expensive one.
  double? get averageBookingValue =>
      confirmedBookings == 0 ? null : revenueTotal / confirmedBookings;

  String get revenueRecentLabel => formatMoney(revenueRecent);
  String get revenueTotalLabel => formatMoney(revenueTotal);
  String get awaitingAmountLabel => formatMoney(paymentsAwaitingAmount);

  String get cancellationRateLabel =>
      '${(cancellationRate * 100).toStringAsFixed(0)}%';

  String? get occupancyLabel {
    final rate = occupancyRate;
    return rate == null ? null : '${(rate * 100).toStringAsFixed(0)}%';
  }

  /// A one-word verdict for the office card, so a glance separates the three
  /// states that matter without reading any number.
  ActivityLevel get activityLevel {
    if (hasNeverTraded) return ActivityLevel.never;
    if (isTrading) return ActivityLevel.active;
    return ActivityLevel.idle;
  }
}

enum ActivityLevel {
  active('نشط'),
  idle('خامل'),
  never('لم يبدأ');

  const ActivityLevel(this.label);
  final String label;
}

/// How loudly a flag should be shown. [rank] exists so the attention queue can
/// sort by it without depending on the declaration order of the enum.
enum AttentionSeverity {
  critical(2, 'حرج'),
  warning(1, 'تحذير'),
  info(0, 'للعلم');

  const AttentionSeverity(this.rank, this.label);
  final int rank;
  final String label;
}

/// One thing wrong with one office, phrased for someone who has to act on it.
class OfficeAttention {
  const OfficeAttention({
    required this.officeId,
    required this.officeName,
    required this.severity,
    required this.title,
    required this.detail,
  });

  final String officeId;
  final String officeName;
  final AttentionSeverity severity;
  final String title;
  final String detail;
}

/// Matches the money format the rest of the dashboard uses: whole pounds when
/// the amount is whole, two decimals otherwise.
String formatMoney(double amount) {
  final rounded = amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  return '$rounded ج.م';
}
