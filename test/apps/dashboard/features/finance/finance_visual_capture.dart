/// Visual QA harness for المركز المالي — the finance module's light-mode
/// design audit. Dark mode is captured once for comparison only; this pass is
/// not changing it.
///
/// The module was recently expanded with more analytics (revenue hero,
/// four-tile KPI band, attention queue, charts, ranked lists, and a
/// three-statement reconciliation), none of which can be judged from code:
/// real money figures, real chart shapes, and a dense attention panel are the
/// only way to see whether the light palette actually reads.
///
/// Not a test of behaviour and deliberately not part of the suite's
/// assertions: run it with `--update-goldens` and look at the PNGs it writes
/// to `_captures/`.
///
///     flutter test test/apps/dashboard/features/finance/finance_visual_capture.dart --update-goldens
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/theme/app_surface_style.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_color_scheme.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_dark_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_light_colors.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_filter_memory.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_money_model.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/cubit/finance_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/cubit/finance_state.dart';
import 'package:bmt_app/apps/dashboard/features/finance/presentation/screens/finance_screen.dart';

const _captureFont = 'CaptureArabic';

void main() {
  setUpAll(() async {
    const path = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';
    final file = File(path);
    if (file.existsSync()) {
      final loader = FontLoader(_captureFont)
        ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      await loader.load();
    }

    // Registers the real MaterialIcons glyphs under the font family every
    // `Icon(Icons.*)` in the module expects, so icons render as themselves
    // instead of tofu boxes in the captures. `flutter test` sets FLUTTER_ROOT
    // for its child process, which is the only portable way to find the SDK's
    // bundled font on any machine this runs on.
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      final iconFont = File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (iconFont.existsSync()) {
        final iconLoader = FontLoader('MaterialIcons')
          ..addFont(
            Future.value(ByteData.sublistView(iconFont.readAsBytesSync())),
          );
        await iconLoader.load();
      }
    }
  });

  setUp(() {
    DashboardFilterMemory.instance.clear();
    DashboardSectionStateStore.instance.clear();
  });
  tearDown(() {
    DashboardFilterMemory.instance.clear();
    DashboardSectionStateStore.instance.clear();
  });

  testWidgets('overview, light', (tester) async {
    await _capture(
      tester,
      'finance_1_full_light',
      dark: false,
      section: FinanceSection.overview,
      height: 2250,
    );
  });

  testWidgets('overview, dark (comparison only)', (tester) async {
    await _capture(
      tester,
      'finance_2_full_dark',
      dark: true,
      section: FinanceSection.overview,
      height: 2250,
    );
  });

  testWidgets('ledger, light', (tester) async {
    await _capture(
      tester,
      'finance_3_ledger_light',
      dark: false,
      section: FinanceSection.ledger,
      height: 2200,
    );
  });
}

// ---------------------------------------------------------------------------
// Fake data
//
// Sixty days of ledger activity — booking fares and package purchases mixed
// together, spanning every status the module reports on, so the default
// "آخر ٣٠ يوم" window has real month-over-month comparison data and every
// breakdown (method, status, type, route, client, weekday) has more than one
// bucket to rank. Wallet movements and settled refunds are dated *outside*
// that window on purpose: the three-statement identity is asserted to the
// piastre, and the simplest way to keep it honestly balanced in fake data is
// to keep every wallet-side event out of the window the headline figures are
// computed over, rather than fight the arithmetic.
// ---------------------------------------------------------------------------

const _routes = <(String, String)>[
  ('القاهرة', 'الإسكندرية'),
  ('المنصورة', 'القاهرة'),
  ('طنطا', 'الإسكندرية'),
  ('القاهرة', 'أسيوط'),
  ('الزقازيق', 'القاهرة'),
  ('بورسعيد', 'القاهرة'),
  ('القاهرة', 'الغردقة'),
];

const _clientNames = [
  'منى عبد الرحمن',
  'كريم الشاذلي',
  'سارة مجدي',
  'أحمد الشرقاوي',
  'نورهان فتحي',
  'أيمن الجندي',
  'هبة سليمان',
  'رامي عز الدين',
  'محمود يوسف',
  'ياسمين طارق',
  'عبد الرحمن فتحي',
  'دينا الحداد',
];

const _packageNames = [
  'أسبوع عمل (٥ أيام)',
  'أسبوعين عمل (١٠ أيام)',
  'باقة شهرية',
  'ثلاثة أشهر',
];

const _packagePrices = [900.0, 1600.0, 2200.0, 4200.0];
const _packageTripCounts = [5, 10, 22, 66];

/// Builds sixty days of ledger rows plus the matching subscription records,
/// each subscription contributing exactly the ledger row [FinanceLedger.build]
/// would have produced for it — done by hand here since the harness never
/// touches the datasource layer.
({List<FinanceLedgerEntry> ledger, List<SubscriptionRecord> subscriptions})
_buildLedgerAndSubscriptions(DateTime now) {
  final entries = <FinanceLedgerEntry>[];
  final subscriptions = <SubscriptionRecord>[];
  var seq = 1;

  for (var daysAgo = 59; daysAgo >= 0; daysAgo--) {
    final day = DateTime(now.year, now.month, now.day - daysAgo);
    final recentBoost = daysAgo <= 30 ? 1 : 0;
    final weekendBoost =
        (day.weekday == DateTime.thursday || day.weekday == DateTime.friday)
        ? 1
        : 0;
    final perDay = 1 + recentBoost + weekendBoost + (daysAgo % 3 == 0 ? 1 : 0);

    for (var k = 0; k < perDay; k++) {
      final route = _routes[seq % _routes.length];
      final client = _clientNames[seq % _clientNames.length];
      final amount = (75 + (seq * 23) % 240).toDouble();
      final hour = 7 + (seq * 5) % 14;
      final minute = (seq * 13) % 60;
      final date = DateTime(day.year, day.month, day.day, hour, minute);
      final cycle = seq % 20;
      final code = 'BK-91${seq.toString().padLeft(3, '0')}';

      PaymentStatus status;
      var bookingState = FinanceBookingState.travelled;
      var awaitingReview = false;

      if (cycle < 14) {
        status = PaymentStatus.success;
        bookingState = daysAgo <= 1
            ? FinanceBookingState.live
            : FinanceBookingState.travelled;
      } else if (cycle < 17) {
        status = PaymentStatus.pending;
        bookingState = FinanceBookingState.live;
        awaitingReview = cycle == 14;
      } else if (cycle == 17) {
        status = PaymentStatus.cancelled;
        bookingState = FinanceBookingState.cancelled;
      } else if (cycle == 18) {
        // Collected, then the seat was cancelled — a stranded liability.
        status = PaymentStatus.success;
        bookingState = FinanceBookingState.cancelled;
      } else {
        status = PaymentStatus.refunded;
        bookingState = FinanceBookingState.cancelled;
      }

      entries.add(
        FinanceLedgerEntry(
          id: 'pay-$seq',
          type: FinanceEntryType.booking,
          party: client,
          reference: code,
          amount: amount,
          method: FinancePaymentMethod
              .values[seq % FinancePaymentMethod.values.length],
          status: status,
          date: date,
          bookingState: bookingState,
          awaitingReview: awaitingReview,
          context: FinanceEntryContext(
            reference: code,
            phone: '01${100000000 + seq}',
            origin: route.$1,
            destination: route.$2,
            serviceDate: date.add(const Duration(days: 1)),
            hasReceipt: status != PaymentStatus.cancelled,
          ),
        ),
      );
      seq++;
    }

    if (daysAgo % 5 == 0) {
      final client = _clientNames[(seq + 2) % _clientNames.length];
      final packageIndex = seq % _packageNames.length;
      final price = _packagePrices[packageIndex];
      final tripsCount = _packageTripCounts[packageIndex];
      final subCycle = seq % 5;
      final subDate = day.add(const Duration(hours: 10));

      SubscriptionStatus subStatus;
      double paid;
      double remaining = 0;
      var awaitingReviewSub = false;

      switch (subCycle) {
        case 0:
          subStatus = SubscriptionStatus.active;
          paid = price;
        case 1:
          subStatus = SubscriptionStatus.expired;
          paid = price;
        case 2:
          // Part-paid package still earning.
          subStatus = SubscriptionStatus.active;
          paid = price * 0.6;
          remaining = price - paid;
        case 3:
          subStatus = SubscriptionStatus.pendingPayment;
          paid = 0;
          awaitingReviewSub = true;
        default:
          subStatus = SubscriptionStatus.cancelled;
          paid = 0;
      }

      final tripsUsed = subStatus == SubscriptionStatus.expired
          ? tripsCount
          : (tripsCount * 0.4).round();

      final record = SubscriptionRecord(
        id: 'sub-$seq',
        clientName: client,
        packageName: _packageNames[packageIndex],
        amount: price,
        createdAt: subDate,
        startDate: subDate.add(const Duration(days: 1)),
        endDate: subDate.add(const Duration(days: 30)),
        status: subStatus,
        remainingRides: (tripsCount - tripsUsed).clamp(0, tripsCount),
        tripsCount: tripsCount,
        tripsUsed: tripsUsed,
        paidAmount: paid,
        remainingAmount: remaining,
        awaitingReview: awaitingReviewSub,
      );
      subscriptions.add(record);

      entries.add(
        FinanceLedgerEntry(
          id: record.id,
          type: FinanceEntryType.subscription,
          party: record.clientName,
          reference: record.packageName,
          amount: FinanceLedger.subscriptionCollectedAmount(record),
          status: FinanceLedger.subscriptionMoneyStatus(record.status),
          date: record.createdAt,
          awaitingReview: record.awaitingReview,
          outstanding: record.status == SubscriptionStatus.cancelled
              ? 0
              : record.remainingAmount,
          context: FinanceEntryContext(
            packageName: record.packageName,
            serviceDate: record.startDate,
          ),
        ),
      );
      seq++;
    }
  }

  entries.sort((a, b) => b.date.compareTo(a.date));
  return (ledger: entries, subscriptions: subscriptions);
}

/// A handful of refund requests: some already settled (mirrored on their
/// booking as [PaymentStatus.refunded] in the ledger, never double-counted
/// here), and a few genuinely pending — money that may still have to go back
/// on a booking that currently reads as collected.
List<RefundRequest> _buildRefundRequests(
  List<FinanceLedgerEntry> ledger,
  DateTime now,
) {
  final refunded = ledger
      .where(
        (e) =>
            e.type == FinanceEntryType.booking &&
            e.status == PaymentStatus.refunded,
      )
      .take(4)
      .toList();
  final collected = ledger
      .where(
        (e) =>
            e.type == FinanceEntryType.booking &&
            e.status == PaymentStatus.success &&
            e.bookingState != FinanceBookingState.cancelled,
      )
      .take(3)
      .toList();

  return [
    for (final entry in refunded)
      RefundRequest(
        id: 'refund-${entry.id}',
        transactionId: entry.id,
        clientName: entry.party,
        amount: entry.amount,
        date: entry.date,
        status: RefundStatus.approved,
        reason: 'إلغاء الرحلة من العميل',
      ),
    for (final (i, entry) in collected.indexed)
      RefundRequest(
        id: 'refund-pending-${entry.id}',
        transactionId: entry.id,
        clientName: entry.party,
        amount: entry.amount,
        date: now.subtract(Duration(days: i + 1)),
        status: i == 2 ? RefundStatus.rejected : RefundStatus.pending,
        reason: i == 2 ? 'تجاوز مهلة الإلغاء' : 'تغيير في موعد الرحلة',
      ),
  ];
}

/// Wallet movements and settled refunds, dated 40–75 days back — outside the
/// default "آخر ٣٠ يوم" window — so the three-statement identity balances
/// exactly for the window the overview leads with, while [currentLiability]
/// still gives the statements panel a real, non-zero figure to show.
WalletFinancePosition _buildWalletPosition(DateTime now) {
  return WalletFinancePosition(
    currentLiability: 18400,
    movements: [
      WalletMovement(
        date: now.subtract(const Duration(days: 42)),
        kind: WalletMovementKind.refund,
        amount: 320,
      ),
      WalletMovement(
        date: now.subtract(const Duration(days: 45)),
        kind: WalletMovementKind.cashback,
        amount: 150,
      ),
      WalletMovement(
        date: now.subtract(const Duration(days: 50)),
        kind: WalletMovementKind.manualCredit,
        amount: 400,
      ),
      WalletMovement(
        date: now.subtract(const Duration(days: 55)),
        kind: WalletMovementKind.walletSpend,
        amount: -280,
      ),
      WalletMovement(
        date: now.subtract(const Duration(days: 60)),
        kind: WalletMovementKind.walletTopup,
        amount: 500,
      ),
      WalletMovement(
        date: now.subtract(const Duration(days: 70)),
        kind: WalletMovementKind.manualDebit,
        amount: -90,
      ),
    ],
    refunds: [
      SettledRefund(
        settledAt: now.subtract(const Duration(days: 44)),
        amount: 320,
        toWallet: true,
      ),
      SettledRefund(
        settledAt: now.subtract(const Duration(days: 48)),
        amount: 180,
        toWallet: false,
      ),
    ],
  );
}

FinanceLoaded _buildState({
  required DateTime now,
  required FinanceSection section,
}) {
  final built = _buildLedgerAndSubscriptions(now);
  final loaded = FinanceLoaded(
    ledger: built.ledger,
    refundRequests: _buildRefundRequests(built.ledger, now),
    subscriptions: built.subscriptions,
    walletPosition: _buildWalletPosition(now),
    loadedAt: now,
    section: section,
  );
  return loaded;
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required bool dark,
  required FinanceSection section,
  double width = 1440,
  required double height,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final now = DateTime.now();
  final state = _buildState(now: now, section: section);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _themeWithHostFont(dark: dark),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: BlocProvider<FinanceCubit>.value(
              value: _StaticFinanceCubit(state),
              child: FinanceScreen(onOpenModule: (_) {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byKey(key), matchesGoldenFile('_captures/$name.png'));
}

/// [DashboardAppTheme] itself builds its text theme through
/// `GoogleFonts.cairoTextTheme()`, which the test binding's blocked network
/// turns into a hard failure — so this hand-builds a [ThemeData] from the
/// same [DashboardLightColors]/[DashboardDarkColors] source and
/// [AppSurfaceStyle.ewt] card treatment `DashboardAppTheme` uses, with the
/// host font substituted directly. The palette and card language are the
/// real EWT ones; only the glyphs differ.
ThemeData _themeWithHostFont({required bool dark}) {
  final scheme = dark ? dashboardDarkColorScheme() : dashboardLightColorScheme();
  final background = dark
      ? DashboardDarkColors.background
      : DashboardLightColors.background;
  final shadow = dark ? DashboardDarkColors.shadow : DashboardLightColors.shadow;
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    fontFamily: _captureFont,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    cardColor: scheme.surface,
    dividerColor: scheme.outline,
    shadowColor: shadow,
    extensions: [AppSurfaceStyle.ewt(scheme)],
  );
}

class _StaticFinanceCubit extends Cubit<FinanceState> implements FinanceCubit {
  _StaticFinanceCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
