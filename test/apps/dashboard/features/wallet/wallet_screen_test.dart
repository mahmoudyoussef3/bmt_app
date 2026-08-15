import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/refund_request.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet_vocabulary.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/presentation/cubit/wallet_state.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/presentation/screens/wallet_screen.dart';

import 'wallet_test_fixtures.dart';

/// Emits states directly, so these tests exercise rendering and permission
/// gating rather than the orchestration already covered by the cubit tests.
class _FakeWalletCubit extends Cubit<WalletState> implements WalletCubit {
  _FakeWalletCubit(super.initialState);

  final List<String> calls = [];

  @override
  Future<void> load() async => calls.add('load');

  @override
  Future<void> refresh() async => calls.add('refresh');

  @override
  void setTab(WalletTab tab) {
    calls.add('setTab:${tab.name}');
    final current = state;
    if (current is WalletLoadedState) emit(current.copyWith(tab: tab));
  }

  @override
  Future<void> selectCustomer(String? clientId) async {
    calls.add('select:$clientId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> _pump(
  WidgetTester tester,
  WalletState state, {
  bool canAdjust = true,
  bool canApprove = true,
}) async {
  // 1600x1200: wide enough for MasterDetailLayout to split, so the detail pane
  // renders beside the directory rather than replacing it.
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: BlocProvider<WalletCubit>.value(
            value: _FakeWalletCubit(state),
            child: WalletScreen(canAdjust: canAdjust, canApprove: canApprove),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

WalletLoadedState _loaded({
  WalletTab tab = WalletTab.directory,
  bool withSelection = false,
  List<RefundRequest> queue = const [],
  WalletStatus walletStatus = WalletStatus.active,
  List<RefundRequest> pendingRefunds = const [],
}) => WalletLoadedState(
  overview: overviewFixture(),
  directory: WalletDirectoryPage(total: 1, rows: [directoryEntryFixture()]),
  tab: tab,
  selectedClientId: withSelection ? 'c1' : null,
  summary: withSelection
      ? summaryFixture(status: walletStatus, pendingRefunds: pendingRefunds)
      : null,
  refundQueue: queue,
  ledger: WalletLedgerPage(
    total: 1,
    sumCredit: 200,
    sumDebit: 0,
    rows: [entryFixture(clientName: 'أحمد محمود')],
  ),
);

/// Finds a *button* carrying [label], as opposed to the label appearing
/// anywhere on screen. The distinction matters for permission tests: a support
/// agent legitimately sees "كاش باك" as a totals tile and as a ledger row type,
/// and must not see it as an action.
Finder _button(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is FilledButton ||
        widget is OutlinedButton ||
        widget is TextButton ||
        widget is ElevatedButton,
  ),
);

/// Opens the module summary, which every dashboard header now starts folded.
///
/// The overview strip is behind that fold, so a test that wants its figures
/// does what the operator does: press «الملخص».
Future<void> _openSummary(WidgetTester tester) async {
  await tester.tap(find.text('الملخص'));
  await tester.pumpAndSettle();
}

void main() {
  // The fold is remembered process-wide for the session, so without this one
  // test's press would decide the next test's starting state.
  setUp(DashboardSectionStateStore.instance.clear);

  group('module chrome', () {
    testWidgets('the header names the balance as a liability', (tester) async {
      await _pump(tester, _loaded());
      expect(find.text('محفظة العملاء'), findsOneWidget);

      await _openSummary(tester);

      // The §2.2 correction, made visible: a wallet balance is money owed back,
      // not money earned. If this label ever reads "إيراد" the report is lying.
      expect(find.text('الأرصدة القائمة'), findsOneWidget);
    });

    testWidgets('the pending-refund KPI carries a count', (tester) async {
      await _pump(tester, _loaded());
      await _openSummary(tester);

      expect(find.text('طلبات معلّقة'), findsOneWidget);
    });
  });

  group('directory and detail', () {
    testWidgets('with no customer chosen the detail pane explains itself', (
      tester,
    ) async {
      await _pump(tester, _loaded());

      expect(find.text('اختر عميلاً لعرض محفظته'), findsOneWidget);
    });

    testWidgets('a chosen customer shows the balance and the ledger', (
      tester,
    ) async {
      await _pump(tester, _loaded(withSelection: true));

      expect(find.text('الرصيد الحالي'), findsOneWidget);
      expect(find.text('سجل الحركات'), findsOneWidget);
      // Every row carries its sequence number and the balance it produced.
      expect(find.text('#12'), findsOneWidget);
      expect(find.textContaining('الرصيد 250.00'), findsWidgets);
    });

    testWidgets('a pending refund is surfaced inline, not hidden in a tab', (
      tester,
    ) async {
      await _pump(
        tester,
        _loaded(withSelection: true, pendingRefunds: [refundFixture()]),
      );

      // The control from §8.2: an operator must not be able to issue a second
      // refund while unaware one is already waiting.
      expect(find.textContaining('قيد المراجعة'), findsWidgets);
      expect(find.text('مراجعة واعتماد'), findsOneWidget);
    });

    testWidgets('a frozen wallet says so and disables only the debit', (
      tester,
    ) async {
      await _pump(
        tester,
        _loaded(withSelection: true, walletStatus: WalletStatus.frozen),
      );

      expect(find.text('محفظة مجمّدة'), findsOneWidget);
      final debit = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('خصم'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(debit.onPressed, isNull);
      // Crediting a frozen wallet stays possible — you must always be able to
      // refund someone.
      final cashback = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('كاش باك'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(cashback.onPressed, isNotNull);
    });
  });

  group('permissions', () {
    testWidgets('a support agent sees balances and history', (tester) async {
      await _pump(
        tester,
        _loaded(withSelection: true),
        canAdjust: false,
        canApprove: false,
      );

      // They are the ones who hear "where is my money"; denying visibility just
      // makes them guess.
      expect(find.text('الرصيد الحالي'), findsOneWidget);
      expect(find.text('سجل الحركات'), findsOneWidget);
    });

    testWidgets('a support agent gets no adjustment control at all', (
      tester,
    ) async {
      await _pump(
        tester,
        _loaded(withSelection: true),
        canAdjust: false,
        canApprove: false,
      );

      // Buttons, not bare text: "كاش باك" is also a *totals* tile the agent is
      // entitled to see, and asserting on the label alone would forbid the
      // visibility this role is supposed to have.
      expect(_button('كاش باك'), findsNothing);
      expect(_button('إضافة رصيد'), findsNothing);
      expect(_button('خصم'), findsNothing);
      expect(_button('تجميد'), findsNothing);
      expect(_button('التحقق من السجل'), findsNothing);
      expect(_button('عكس'), findsNothing);
    });

    testWidgets('a support agent gets a refund *request*, not a refund', (
      tester,
    ) async {
      await _pump(
        tester,
        _loaded(withSelection: true),
        canAdjust: false,
        canApprove: false,
      );

      expect(_button('طلب استرداد'), findsOneWidget);
      // "استرداد" still appears as a ledger row's *type*; what an agent must
      // not have is the action.
      expect(_button('استرداد'), findsNothing);
    });

    testWidgets('an owner gets the full action bar', (tester) async {
      await _pump(tester, _loaded(withSelection: true));

      expect(_button('استرداد'), findsOneWidget);
      expect(_button('كاش باك'), findsOneWidget);
      expect(_button('إضافة رصيد'), findsOneWidget);
      expect(_button('خصم'), findsOneWidget);
      expect(_button('تجميد'), findsOneWidget);
    });

    testWidgets('export is owner-only', (tester) async {
      await _pump(tester, _loaded(tab: WalletTab.activity));
      expect(find.text('تصدير'), findsOneWidget);

      await _pump(
        tester,
        _loaded(tab: WalletTab.activity),
        canAdjust: false,
        canApprove: false,
      );
      expect(find.text('تصدير'), findsNothing);
    });

    testWidgets('a support agent cannot decide a queued refund', (
      tester,
    ) async {
      await _pump(
        tester,
        _loaded(tab: WalletTab.refunds, queue: [refundFixture()]),
        canAdjust: false,
        canApprove: false,
      );

      expect(find.text('اعتماد وتنفيذ'), findsNothing);
      expect(find.text('رفض'), findsNothing);
      // …but they can see it, which is what makes escalation work.
      expect(find.text('أحمد محمود'), findsWidgets);
    });

    testWidgets('an owner can decide and can start a batch refund', (
      tester,
    ) async {
      await _pump(
        tester,
        _loaded(tab: WalletTab.refunds, queue: [refundFixture()]),
      );

      expect(find.text('اعتماد وتنفيذ'), findsOneWidget);
      expect(find.text('استرداد رحلة ملغاة'), findsOneWidget);
    });
  });

  group('activity', () {
    testWidgets('the ledger shows the customer column and the totals', (
      tester,
    ) async {
      await _pump(tester, _loaded(tab: WalletTab.activity));

      expect(find.text('الحركات المالية'), findsWidgets);
      expect(find.textContaining('إضافات 200.00'), findsOneWidget);
      expect(find.text('بها تصحيح'), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('a load failure offers a retry', (tester) async {
      await _pump(tester, const WalletErrorState('تعذر التحميل'));

      expect(find.text('تعذر التحميل'), findsOneWidget);
      expect(find.byType(FilledButton), findsWidgets);
    });
  });
}
