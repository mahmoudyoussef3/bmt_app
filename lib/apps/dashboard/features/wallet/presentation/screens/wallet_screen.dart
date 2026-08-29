import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/master_detail_layout.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/refund_request.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import '../models/wallet_views.dart';
import '../widgets/wallet_action_dialogs.dart';
import '../widgets/wallet_amount_dialog.dart';
import '../widgets/wallet_detail_pane.dart';
import '../widgets/wallet_directory_row.dart';
import '../widgets/wallet_format.dart';
import '../widgets/wallet_kpi_strip.dart';
import '../widgets/wallet_ledger_entry_tile.dart';
import '../widgets/wallet_list_section.dart';
import '../widgets/wallet_refund_dialog.dart';
import '../widgets/wallet_refund_row.dart';
import '../widgets/wallet_toolbar.dart';

/// محفظة العملاء — the wallet and financial-adjustments module.
///
/// One screen, three tabs — the customer directory and its wallet detail pane,
/// the office-wide financial activity search, and the refund requests queue —
/// and since the 2026-08-30 المالية pass the three are **one shape**:
///
/// ```
/// module header  → four stat tiles for the tab you are on
/// toolbar        → surface strip · pinned search + sort · folded filters
/// results header → what this list is, and how much of it is on screen
/// list card      → rows in one chrome, then the console's pager
/// ```
///
/// Before it, each tab had grown its own answer to the same three questions:
/// the directory had a bare search box and a tile of its own design, الحركات a
/// tinted well of eleven chips, and الاسترداد neither filters nor paging. The
/// figures moved between tabs, so did the controls, and the fifth header tile
/// never changed no matter which list it crowned.
///
/// Two capabilities drive what renders. They come from the signed-in office
/// role, and the server checks the same thing again inside every RPC — the UI
/// decides what is worth showing, `office_can` decides what is allowed.
class WalletScreen extends StatelessWidget {
  const WalletScreen({
    super.key,
    required this.canAdjust,
    required this.canApprove,
  });

  /// `walletAdjustments` — cashback, credit, debit.
  final bool canAdjust;

  /// `walletApprovals` — decide refunds, reverse, freeze, verify, export.
  final bool canApprove;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletCubit, WalletState>(
      listenWhen: (previous, current) =>
          current is WalletLoadedState &&
          (current.actionError != null || current.actionMessage != null),
      listener: (context, state) {
        if (state is! WalletLoadedState) return;
        final message = state.actionError ?? state.actionMessage;
        if (message == null) return;
        final isError = state.actionError != null;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: isError
                  ? Theme.of(context).colorScheme.error
                  : null,
              duration: Duration(seconds: isError ? 6 : 3),
            ),
          );
      },
      builder: (context, state) => switch (state) {
        WalletLoadingState() => const DashboardLoading(),
        WalletErrorState(:final message) => DashboardErrorState(
          message: message,
          onRetry: () => context.read<WalletCubit>().load(),
        ),
        WalletLoadedState() => _WalletBody(
          state: state,
          canAdjust: canAdjust,
          canApprove: canApprove,
        ),
      },
    );
  }
}

class _WalletBody extends StatelessWidget {
  const _WalletBody({
    required this.state,
    required this.canAdjust,
    required this.canApprove,
  });

  final WalletLoadedState state;
  final bool canAdjust;
  final bool canApprove;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WalletCubit>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: DashboardIcons.walletActive,
          title: 'محفظة العملاء',
          subtitle:
              'أرصدة العملاء والمرتجعات والتسويات — سجل غير قابل للتعديل، كل حركة باسم من نفّذها.',
          actions: [
            if (state.busy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.small),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            FilledButton.tonalIcon(
              onPressed: state.busy ? null : cubit.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تحديث'),
            ),
          ],
          sectionId: DashboardSectionIds.walletHeader,
          // Open, unlike most headers on the console: these four tiles *are*
          // the tab's headline, and they change with it. Folded, the module
          // opens on a list with no answer to "how much, and how much needs
          // me" — which is the first question asked of a money screen.
          initiallyExpanded: true,
          collapsedSummary: DashboardSectionSummary(
            items: WalletKpiStrip.summaryFor(state),
          ),
          summary: WalletKpiStrip(state: state),
        ),
        const SizedBox(height: AppSpacing.medium),
        WalletToolbar(state: state),
        const SizedBox(height: AppSpacing.medium),
        switch (state.tab) {
          WalletTab.directory => _buildDirectory(context, cubit),
          WalletTab.activity => _buildActivity(context, cubit),
          WalletTab.refunds => _buildRefunds(context, cubit),
        },
      ],
    );
  }

  /// Surface 1 — the directory, and the wallet it opens beside itself.
  ///
  /// The list keeps the module's standard frame and the detail pane sits next
  /// to it, so choosing a customer never costs the operator their place in the
  /// list they were reading.
  Widget _buildDirectory(BuildContext context, WalletCubit cubit) {
    final now = DateTime.now();
    final rows = state.directoryPageRows;
    final filters = state.directoryFilters;
    final searching = state.directorySearch.trim().isNotEmpty;

    return MasterDetailLayout(
      masterFlex: 2,
      detailFlex: 3,
      placeholderTitle: 'اختر عميلاً لعرض محفظته',
      placeholderSubtitle:
          'كل حركة مالية تبدأ من عميل محدّد — لا توجد صفحة تسويات عامة، وهذا مقصود.',
      master: WalletListSection(
        icon: DashboardIcons.customers,
        title: 'قائمة العملاء',
        noun: 'عميل',
        total: state.directoryRows.length,
        page: walletPageIndex(state.directoryRows.length, state.directoryPage),
        onPageChanged: cubit.setDirectoryPage,
        // Not a cap *notice*: the directory RPC returns a page of the customer
        // base, not its newest end, so "يعرض أحدث ٦٠ عميل" would be a claim
        // about time that the ordering does not support. The range says what
        // it is instead, and points at the control that reaches the rest.
        totalNote: state.directoryCapReached
            ? 'من ${WalletFormat.count(state.directory.total)} في المكتب — ابحث للوصول لغيرهم'
            : null,
        empty: DashboardEmptyState(
          icon: DashboardIcons.customers,
          title: searching || filters.activeCount > 0
              ? 'لا توجد نتائج مطابقة'
              : 'لا يوجد عملاء بعد',
          message: searching || filters.activeCount > 0
              ? 'جرّب اسمًا أو رقم هاتف آخر، أو وسّع نطاق التصفية.'
              : 'يظهر هنا كل عميل حجز أو اشترك مع مكتبك.',
          action: filters.activeCount == 0 && !searching
              ? null
              : TextButton.icon(
                  onPressed: cubit.clearDirectoryFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                  label: const Text('إزالة التصفية'),
                ),
        ),
        rows: [
          for (final entry in rows)
            WalletDirectoryRow(
              entry: entry,
              now: now,
              selected: entry.clientId == state.selectedClientId,
              onTap: () => cubit.selectCustomer(entry.clientId),
            ),
        ],
      ),
      detail: state.hasSelection
          ? Padding(
              padding: const EdgeInsets.only(right: AppSpacing.medium),
              child: WalletDetailPane(
                summary: state.summary,
                loading: state.detailLoading,
                busy: state.busy,
                canAdjust: canAdjust,
                canApprove: canApprove,
                chainVerification: state.chainVerification,
                onRefund: () => _refund(context, cubit),
                onCashback: () => _adjust(context, cubit, WalletKind.cashback),
                onCredit: () =>
                    _adjust(context, cubit, WalletKind.manualCredit),
                onDebit: () => _adjust(context, cubit, WalletKind.manualDebit),
                onFreeze: () => _freeze(context, cubit),
                onVerifyChain: cubit.verifyChain,
                onReverse: (entry) => _reverse(context, cubit, entry),
                onDecideRefund: (refund, approve) =>
                    _decideRefund(context, cubit, refund, approve),
              ),
            )
          : null,
    );
  }

  /// Surface 2 — office-wide financial activity. Answers "what did my staff do
  /// this week", with every predicate evaluated server-side in one query so the
  /// count in the header and the rows below it can never disagree about what
  /// "filtered" meant.
  Widget _buildActivity(BuildContext context, WalletCubit cubit) {
    return WalletListSection(
      icon: DashboardIcons.activity,
      title: 'الحركات المالية',
      noun: 'حركة',
      loading: state.ledgerLoading,
      total: state.activityRows.length,
      page: walletPageIndex(state.activityRows.length, state.activityPage),
      onPageChanged: cubit.setActivityPage,
      capReached: state.activityCapReached,
      capRows: state.ledger.rows.length,
      actions: [
        // Owner-only: a full customer financial history in a spreadsheet is a
        // data-exfiltration surface, and it is the one read that leaves the
        // audited system.
        if (canApprove)
          TextButton.icon(
            onPressed: state.ledger.rows.isEmpty
                ? null
                : () => _export(context),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('تصدير'),
          ),
      ],
      empty: DashboardEmptyState(
        icon: DashboardIcons.activity,
        title: state.filters.isEmpty
            ? 'لا توجد حركات مالية بعد'
            : 'لا توجد حركات مطابقة للتصفية',
        message: state.filters.isEmpty
            ? 'تظهر هنا كل حركة على محافظ عملاء المكتب.'
            : 'وسّع نطاق البحث أو أزل بعض عناصر التصفية.',
        action: state.filters.isEmpty
            ? null
            : TextButton.icon(
                onPressed: () =>
                    cubit.applyFilters(const WalletLedgerFilters()),
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: const Text('إزالة التصفية'),
              ),
      ),
      rows: [
        for (final entry in state.activityPageRows)
          WalletLedgerEntryTile(entry: entry, showCustomer: true),
      ],
    );
  }

  /// Surface 3 — the refund requests queue, and the whole refund record behind
  /// it. The approval step had no home in the console until this queue existed;
  /// the scope filter is what lets it stay a *queue* while still answering
  /// "did we already refund this?".
  Widget _buildRefunds(BuildContext context, WalletCubit cubit) {
    final filters = state.refundFilters;

    return WalletListSection(
      icon: Icons.assignment_return_rounded,
      title: 'طلبات الاسترداد',
      noun: 'طلب',
      loading: state.queueLoading,
      total: state.refundRows.length,
      page: walletPageIndex(state.refundRows.length, state.refundPage),
      onPageChanged: cubit.setRefundPage,
      actions: [
        if (canApprove)
          TextButton.icon(
            onPressed: () => _batchRefund(context, cubit),
            icon: const Icon(Icons.event_busy_rounded, size: 18),
            label: const Text('استرداد رحلة ملغاة'),
          ),
      ],
      // Keyed on whether the *record* is empty, not on whether a filter is
      // active. The tab opens scoped to «بانتظار القرار», which is not counted
      // as a filter — so an office whose every refund is settled would
      // otherwise be told it has no refunds at all while holding a year of
      // them.
      empty: state.refundQueue.isEmpty
          ? const DashboardEmptyState(
              icon: Icons.assignment_turned_in_outlined,
              title: 'لا توجد طلبات استرداد',
              message:
                  'تظهر هنا طلبات العملاء وطلبات فريق خدمة العملاء بانتظار قرار المالك.',
            )
          : DashboardEmptyState(
              icon: Icons.assignment_turned_in_outlined,
              title: 'لا توجد طلبات مطابقة للتصفية',
              message:
                  'يحتوي السجل على '
                  '${WalletFormat.count(state.refundQueue.length)} طلب خارج نطاق التصفية الحالية.',
              action: TextButton.icon(
                onPressed: filters.scope == WalletRefundScope.all
                    ? cubit.clearRefundFilters
                    : () => cubit.applyRefundFilters(
                        filters.copyWith(scope: WalletRefundScope.all),
                      ),
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: Text(
                  filters.scope == WalletRefundScope.all
                      ? 'إزالة التصفية'
                      : 'اعرض كل الطلبات',
                ),
              ),
            ),
      rows: [
        for (final refund in state.refundPageRows)
          WalletRefundRow(
            refund: refund,
            canDecide: canApprove,
            onDecide: (refund, approve) =>
                _decideRefund(context, cubit, refund, approve),
            onOpenCustomer: (clientId) {
              cubit.setTab(WalletTab.directory);
              cubit.selectCustomer(clientId);
            },
          ),
      ],
    );
  }

  WalletSummary? get _summary => state.summary;

  void _adjust(BuildContext context, WalletCubit cubit, WalletKind kind) {
    final summary = _summary;
    if (summary == null) return;
    showDialog<bool>(
      context: context,
      builder: (_) => WalletAmountDialog(
        cubit: cubit,
        kind: kind,
        customer: summary.customer,
        wallet: summary.wallet,
        policy: state.overview.policy,
      ),
    );
  }

  void _refund(BuildContext context, WalletCubit cubit) {
    final summary = _summary;
    if (summary == null) return;
    showDialog<bool>(
      context: context,
      builder: (_) => WalletRefundDialog(
        cubit: cubit,
        customer: summary.customer,
        canSettleImmediately: canApprove,
      ),
    );
  }

  void _reverse(
    BuildContext context,
    WalletCubit cubit,
    WalletTransaction entry,
  ) {
    showDialog<bool>(
      context: context,
      builder: (_) => WalletReverseDialog(cubit: cubit, entry: entry),
    );
  }

  void _freeze(BuildContext context, WalletCubit cubit) {
    final summary = _summary;
    if (summary == null) return;
    showDialog<bool>(
      context: context,
      builder: (_) => WalletFreezeDialog(
        cubit: cubit,
        customer: summary.customer,
        wallet: summary.wallet,
      ),
    );
  }

  void _decideRefund(
    BuildContext context,
    WalletCubit cubit,
    RefundRequest refund,
    bool approve,
  ) {
    showDialog<bool>(
      context: context,
      builder: (_) =>
          RefundDecisionDialog(cubit: cubit, refund: refund, approve: approve),
    );
  }

  void _batchRefund(BuildContext context, WalletCubit cubit) {
    showDialog<bool>(
      context: context,
      builder: (_) => TripBatchRefundDialog(cubit: cubit),
    );
  }

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await context.read<WalletCubit>().exportStatement();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('تم حفظ الملف في $path')));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('تعذر التصدير: ${e.toString()}')),
        );
    }
  }
}
