import 'finance_entities.dart';
import 'finance_money_model.dart';

/// One day of the ledger.
class FinanceDailyPoint {
  final DateTime date;

  /// Money received and kept on this day.
  final double net;

  /// Money received on this day that was later sent back.
  final double refunded;

  /// Invoiced on this day, still uncollected.
  final double pending;

  final int transactions;

  const FinanceDailyPoint({
    required this.date,
    required this.net,
    required this.refunded,
    required this.pending,
    required this.transactions,
  });

  /// Everything received on this day, before reversals.
  double get gross => net + refunded;
}

/// A labelled slice of money — by method, by status, by route, by client, by
/// weekday. One shape for every breakdown table and chart in the module.
class FinanceBreakdownRow {
  final String label;
  final double amount;
  final int count;

  const FinanceBreakdownRow({
    required this.label,
    required this.amount,
    required this.count,
  });

  double shareOf(double total) => total <= 0 ? 0 : amount / total;
}

/// Everything the finance screen shows, derived in pure Dart from the ledger.
///
/// Deriving instead of fetching is deliberate: the KPI band, the charts, the
/// ledger table and the exported statement all read this one object, so the
/// header total and the table total can never disagree, and switching period
/// costs nothing.
///
/// **The arithmetic that matters:**
/// `صافي الإيراد (netRevenue) = إجمالي المتحصلات (grossReceived) − المرتجعات (refunded)`.
/// A refunded booking is counted once into [grossReceived] and once into
/// [refunded], so it contributes exactly zero to [netRevenue] — never twice.
class FinanceAnalytics {
  /// The resolved reporting window — bounds, the words for them, and the
  /// window the deltas are measured against.
  final FinanceWindow window;

  final FinanceDateRange range;

  /// Ledger rows inside the window, newest first.
  final List<FinanceLedgerEntry> entries;

  /// Money received and kept.
  final double netRevenue;

  /// Received, then returned to the client.
  final double refunded;

  /// Invoiced but not collected yet.
  final double pending;

  /// Rejected, failed, or owed on a seat that no longer exists — money that
  /// will never arrive.
  final double cancelled;

  /// The unpaid tail of part-paid packages that were sold in this window.
  /// Outstanding like [pending], but on a row that has already contributed
  /// some collected money, so it cannot simply be added to the pending count.
  final double partPaidOutstanding;

  final double bookingsRevenue;
  final double subscriptionsRevenue;

  final int transactionCount;
  final int paidCount;
  final int pendingCount;
  final int refundedCount;

  final List<FinanceDailyPoint> daily;
  final List<FinanceBreakdownRow> byMethod;
  final List<FinanceBreakdownRow> byStatus;
  final List<FinanceBreakdownRow> byType;
  final List<FinanceBreakdownRow> byRoute;
  final List<FinanceBreakdownRow> byClient;
  final List<FinanceBreakdownRow> byWeekday;

  /// The same analytics over the equally long window immediately before this
  /// one. `null` for [FinancePeriod.all], which has no "before".
  final FinanceAnalytics? previous;

  /// The three statements (§7) for this window.
  ///
  /// Empty — all zeros — when no wallet position was supplied, which is exactly
  /// what the figures should be for an office that has never issued credit.
  /// Every legacy figure above ([netRevenue], [refunded], …) is untouched, so
  /// this is an addition to the module rather than a replacement of it.
  final FinanceMoneyStatements statements;

  const FinanceAnalytics._({
    required this.window,
    required this.range,
    required this.entries,
    required this.netRevenue,
    required this.refunded,
    required this.pending,
    required this.cancelled,
    required this.partPaidOutstanding,
    required this.bookingsRevenue,
    required this.subscriptionsRevenue,
    required this.transactionCount,
    required this.paidCount,
    required this.pendingCount,
    required this.refundedCount,
    required this.daily,
    required this.byMethod,
    required this.byStatus,
    required this.byType,
    required this.byRoute,
    required this.byClient,
    required this.byWeekday,
    required this.previous,
    required this.statements,
  });

  factory FinanceAnalytics.from({
    required List<FinanceLedgerEntry> ledger,
    required FinancePeriod period,
    required DateTime now,
    WalletFinancePosition wallet = const WalletFinancePosition.empty(),
    FinanceDateRange? customRange,
  }) {
    return FinanceAnalytics.forWindow(
      ledger: ledger,
      window: FinanceWindow.resolve(period, now, custom: customRange),
      wallet: wallet,
    );
  }

  /// The general entry point: analytics over an already-resolved window.
  ///
  /// The previous window comes from the window itself rather than being
  /// re-derived here, so "what does السابقة mean" is answered once, in
  /// [FinanceWindow], for calendar months and rolling spans alike.
  factory FinanceAnalytics.forWindow({
    required List<FinanceLedgerEntry> ledger,
    required FinanceWindow window,
    WalletFinancePosition wallet = const WalletFinancePosition.empty(),
  }) {
    final before = window.previous;
    return FinanceAnalytics._compute(
      window: window,
      ledger: ledger,
      range: window.range,
      wallet: wallet,
      previous: before == null
          ? null
          : FinanceAnalytics._compute(
              window: before,
              ledger: ledger,
              range: before.range,
              wallet: wallet,
              previous: null,
            ),
    );
  }

  static FinanceAnalytics _compute({
    required FinanceWindow window,
    required List<FinanceLedgerEntry> ledger,
    required FinanceDateRange range,
    required WalletFinancePosition wallet,
    required FinanceAnalytics? previous,
  }) {
    final entries = ledger.where((e) => range.contains(e.date)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    double net = 0, refunded = 0, pending = 0, cancelled = 0;
    double bookings = 0, subscriptions = 0, partPaidOutstanding = 0;
    var paidCount = 0, pendingCount = 0, refundedCount = 0;

    final byMethod = <FinancePaymentMethod, _Bucket>{};
    final byStatus = <PaymentStatus, _Bucket>{};
    final byType = <FinanceEntryType, _Bucket>{};
    final byRoute = <String, _Bucket>{};
    final byClient = <String, _Bucket>{};
    final byWeekday = <int, _Bucket>{};
    final byDay = <DateTime, _DayBucket>{};

    for (final entry in entries) {
      final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
      final bucket = byDay.putIfAbsent(day, () => _DayBucket());
      bucket.transactions++;

      byStatus.putIfAbsent(entry.status, () => _Bucket()).add(entry.amount);
      byType.putIfAbsent(entry.type, () => _Bucket()).add(entry.amount);

      switch (entry.status) {
        case PaymentStatus.success:
          net += entry.amount;
          paidCount++;
          bucket.net += entry.amount;
          if (entry.type == FinanceEntryType.subscription) {
            subscriptions += entry.amount;
          } else {
            bookings += entry.amount;
          }
        case PaymentStatus.refunded:
          refunded += entry.amount;
          refundedCount++;
          bucket.refunded += entry.amount;
        case PaymentStatus.pending:
          pending += entry.amount;
          pendingCount++;
          bucket.pending += entry.amount;
        case PaymentStatus.cancelled:
          cancelled += entry.amount;
      }

      partPaidOutstanding += entry.outstanding;

      if (!entry.isRealised) continue;
      final method = entry.method;
      if (method != null) {
        byMethod.putIfAbsent(method, () => _Bucket()).add(entry.amount);
      }
      if (entry.type == FinanceEntryType.booking) {
        byRoute.putIfAbsent(entry.reference, () => _Bucket()).add(entry.amount);
      }
      byClient.putIfAbsent(entry.party, () => _Bucket()).add(entry.amount);
      byWeekday
          .putIfAbsent(entry.date.weekday, () => _Bucket())
          .add(entry.amount);
    }

    return FinanceAnalytics._(
      window: window,
      range: range,
      entries: entries,
      netRevenue: net,
      refunded: refunded,
      pending: pending,
      cancelled: cancelled,
      bookingsRevenue: bookings,
      subscriptionsRevenue: subscriptions,
      partPaidOutstanding: partPaidOutstanding,
      transactionCount: entries.length,
      paidCount: paidCount,
      pendingCount: pendingCount,
      refundedCount: refundedCount,
      daily: _dailySeries(byDay: byDay, range: range),
      byMethod: _rank(byMethod.map((k, v) => MapEntry(k.label, v))),
      byStatus: _rank(byStatus.map((k, v) => MapEntry(k.label, v))),
      byType: _rank(byType.map((k, v) => MapEntry(k.pluralLabel, v))),
      byRoute: _rank(byRoute),
      byClient: _rank(byClient),
      byWeekday: _weekdayRows(byWeekday),
      previous: previous,
      
      statements: FinanceMoneyStatements.from(
        soldFare: net + refunded,
        
        // Revenue is keyed on the fare, cash on the tender, and the two differ
        // by exactly the fares paid out of a wallet balance — those raise no
        // external money. `wallet_spend` is reserved and unemitted in V1, so
        // this subtracts zero today; wiring it now is what keeps the control
        // identity balanced on the day wallet checkout ships, instead of
        // turning the panel red for a healthy office.
        externalTender: net + refunded - _walletTender(wallet, range),
        wallet: wallet,
        range: range,
      ),
    );
  }

  /// Fares tendered from a customer's wallet balance inside [range], as a
  /// positive figure. Wallet debits are stored negative.
  static double _walletTender(
    WalletFinancePosition wallet,
    FinanceDateRange range,
  ) {
    var total = 0.0;
    for (final movement in wallet.movements) {
      if (movement.kind != WalletMovementKind.walletSpend) continue;
      if (!range.contains(movement.date)) continue;
      total += movement.amount.abs();
    }
    return total;
  }

  /// The preset behind [window]. Kept as a shorthand because most of the module
  /// only ever wants the label or the identity of the selection.
  FinancePeriod get period => window.period;

  /// What the period bar and the panel subtitles call this window.
  String get periodLabel => window.label;

  /// Every pound that reached the office in the window, reversals included.
  double get grossReceived => netRevenue + refunded;

  /// Everything still genuinely owed to the office from this window's rows:
  /// unpaid fares on live seats, plus the unpaid tail of part-paid packages.
  /// Cancelled seats are not here — nobody is waiting for that money.
  double get receivable => pending + partPaidOutstanding;

  /// Everything invoiced in the window that either arrived or is still live —
  /// the denominator [collectionRate] is a share of. Written-off money
  /// ([cancelled]) is deliberately outside it: an office is not failing to
  /// collect a fare whose seat was released.
  double get billed => grossReceived + receivable;

  /// Share of invoiced money that actually arrived.
  double get collectionRate => billed <= 0 ? 0 : grossReceived / billed;

  /// Share of received money that was handed back.
  double get refundRate => grossReceived <= 0 ? 0 : refunded / grossReceived;

  /// Average value of a collected transaction.
  double get averageTicket => paidCount == 0 ? 0 : netRevenue / paidCount;

  /// Days in the window that saw at least one collected pound.
  int get activeDays => daily.where((d) => d.net > 0).length;

  double get averageDailyRevenue =>
      daily.isEmpty ? 0 : netRevenue / daily.length;

  FinanceDailyPoint? get bestDay {
    if (daily.isEmpty) return null;
    return daily.reduce((a, b) => b.net > a.net ? b : a);
  }

  FinanceDailyPoint? get busiestDay {
    if (daily.isEmpty) return null;
    return daily.reduce((a, b) => b.transactions > a.transactions ? b : a);
  }

  /// Share of revenue produced by the single strongest route — how exposed the
  /// office is to one line going quiet.
  double get routeConcentration {
    if (byRoute.isEmpty || netRevenue <= 0) return 0;
    return byRoute.first.amount / netRevenue;
  }

  /// Running total of net revenue across the window, for the cumulative curve.
  List<FinanceDailyPoint> get cumulativeDaily {
    var running = 0.0;
    var runningCount = 0;
    return [
      for (final point in daily)
        () {
          running += point.net;
          runningCount += point.transactions;
          return FinanceDailyPoint(
            date: point.date,
            net: running,
            refunded: 0,
            pending: 0,
            transactions: runningCount,
          );
        }(),
    ];
  }

  bool get hasComparison => previous != null;

  /// Fractional change vs the previous window, or `null` when the previous
  /// window had nothing to compare against — dividing by zero would print an
  /// impressive but meaningless number.
  double? get netRevenueChange => _change(previous?.netRevenue, netRevenue);
  double? get grossReceivedChange =>
      _change(previous?.grossReceived, grossReceived);
  double? get transactionsChange => _change(
    previous?.transactionCount.toDouble(),
    transactionCount.toDouble(),
  );
  double? get averageTicketChange =>
      _change(previous?.averageTicket, averageTicket);
  double? get refundedChange => _change(previous?.refunded, refunded);

  static double? _change(double? before, double now) {
    if (before == null || before == 0) return null;
    return (now - before) / before;
  }

  FinanceStatement toStatement({required DateTime generatedAt}) {
    return FinanceStatement(
      periodLabel: window.label,
      generatedAt: generatedAt,
      summary: [
        FinanceStatementLine('إيرادات الحجوزات', bookingsRevenue),
        FinanceStatementLine('إيرادات الاشتراكات', subscriptionsRevenue),
        FinanceStatementLine('المرتجعات المنفذة', refunded),
        FinanceStatementLine(
          'إجمالي المتحصلات',
          grossReceived,
          isSubtotal: true,
        ),
        FinanceStatementLine('صافي الإيراد', netRevenue, isTotal: true),
        
        FinanceStatementLine(
          'النقدية المحصّلة',
          statements.cash,
          isSubtotal: true,
        ),
        FinanceStatementLine(
          'التزامات المحفظة (آخر الفترة)',
          statements.liabilityEnd,
          isMemo: true,
        ),
        FinanceStatementLine(
          'تكلفة الحوافز (خارج الصافي)',
          statements.promotionalCost,
          isMemo: true,
        ),
        FinanceStatementLine(
          'قيد التحصيل (خارج الصافي)',
          pending,
          isMemo: true,
        ),
        FinanceStatementLine(
          'مبالغ ملغاة (خارج الصافي)',
          cancelled,
          isMemo: true,
        ),
      ],
      byMethod: byMethod,
      daily: daily,
      entries: entries,
    );
  }

  /// A bounded window is filled edge to edge so a quiet day is a visible zero
  /// on the chart instead of the line silently skipping it. All-time keeps only
  /// the days that exist — padding years of zeros helps nobody.
  static List<FinanceDailyPoint> _dailySeries({
    required Map<DateTime, _DayBucket> byDay,
    required FinanceDateRange range,
  }) {
    if (byDay.isEmpty) return const [];
    final observed = byDay.keys.toList()..sort();

    FinanceDailyPoint pointAt(DateTime day) {
      final bucket = byDay[day];
      return FinanceDailyPoint(
        date: day,
        net: bucket?.net ?? 0,
        refunded: bucket?.refunded ?? 0,
        pending: bucket?.pending ?? 0,
        transactions: bucket?.transactions ?? 0,
      );
    }

    final rangeStart = range.start;
    if (rangeStart == null) {
      return [for (final day in observed) pointAt(day)];
    }

    var cursor = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final stop = DateTime(range.end.year, range.end.month, range.end.day);
    final points = <FinanceDailyPoint>[];
    while (!cursor.isAfter(stop)) {
      points.add(pointAt(cursor));
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }
    return points;
  }

  static List<FinanceBreakdownRow> _rank(Map<String, _Bucket> source) {
    return [
      for (final entry in source.entries)
        FinanceBreakdownRow(
          label: entry.key,
          amount: entry.value.amount,
          count: entry.value.count,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
  }

  /// Saturday-first, the way an Egyptian operating week actually reads.
  static List<FinanceBreakdownRow> _weekdayRows(Map<int, _Bucket> source) {
    const order = [
      (DateTime.saturday, 'السبت'),
      (DateTime.sunday, 'الأحد'),
      (DateTime.monday, 'الاثنين'),
      (DateTime.tuesday, 'الثلاثاء'),
      (DateTime.wednesday, 'الأربعاء'),
      (DateTime.thursday, 'الخميس'),
      (DateTime.friday, 'الجمعة'),
    ];
    return [
      for (final (weekday, label) in order)
        FinanceBreakdownRow(
          label: label,
          amount: source[weekday]?.amount ?? 0,
          count: source[weekday]?.count ?? 0,
        ),
    ];
  }
}

class _Bucket {
  double amount = 0;
  int count = 0;

  void add(double value) {
    amount += value;
    count++;
  }
}

class _DayBucket {
  double net = 0;
  double refunded = 0;
  double pending = 0;
  int transactions = 0;
}

/// A single line of the income statement.
class FinanceStatementLine {
  final String label;
  final double amount;
  final bool isSubtotal;
  final bool isTotal;

  /// Reported for context but deliberately outside the net-revenue arithmetic.
  final bool isMemo;

  const FinanceStatementLine(
    this.label,
    this.amount, {
    this.isSubtotal = false,
    this.isTotal = false,
    this.isMemo = false,
  });
}

/// The exportable financial statement for a period — the same object the
/// Reports tab renders and the CSV/Excel/PDF writer serialises, so a downloaded
/// file can never say something the screen did not.
class FinanceStatement {
  final String periodLabel;
  final DateTime generatedAt;
  final List<FinanceStatementLine> summary;
  final List<FinanceBreakdownRow> byMethod;
  final List<FinanceDailyPoint> daily;
  final List<FinanceLedgerEntry> entries;

  const FinanceStatement({
    required this.periodLabel,
    required this.generatedAt,
    required this.summary,
    required this.byMethod,
    required this.daily,
    required this.entries,
  });
}
