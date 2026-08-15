import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/master_detail_layout.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../data/services/wallet_statement_export_service.dart';
import '../../domain/entities/refund_request.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import '../widgets/wallet_action_dialogs.dart';
import '../widgets/wallet_activity_panel.dart';
import '../widgets/wallet_amount_dialog.dart';
import '../widgets/wallet_detail_pane.dart';
import '../widgets/wallet_directory_panel.dart';
import '../widgets/wallet_overview_strip.dart';
import '../widgets/wallet_refund_dialog.dart';
import '../widgets/wallet_refund_queue_panel.dart';

/// محفظة العملاء — the wallet and financial-adjustments module.
///
/// One screen, four surfaces (§8.1): the customer directory and its wallet
/// detail pane, the office-wide financial activity search, and the refund
/// requests queue.
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
          summary: WalletOverviewStrip(
            overview: state.overview,
            onOpenRefunds: () => cubit.setTab(WalletTab.refunds),
          ),
          // The tab bar is pinned and sits at the card's bottom edge, against
          // the panel it switches — folding the balances must never take the
          // navigation with it.
          pinned: WalletTabBar(
            current: state.tab,
            openRefundCount: state.openRefundCount,
            onChanged: cubit.setTab,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        switch (state.tab) {
          WalletTab.directory => _buildDirectory(context, cubit),
          WalletTab.activity => WalletActivityPanel(
            page: state.ledger,
            filters: state.filters,
            loading: state.ledgerLoading,
            canExport: canApprove,
            onFiltersChanged: cubit.applyFilters,
            onExport: () => _export(context),
          ),
          WalletTab.refunds => WalletRefundQueuePanel(
            refunds: state.refundQueue,
            loading: state.queueLoading,
            canDecide: canApprove,
            onDecide: (refund, approve) =>
                _decideRefund(context, cubit, refund, approve),
            onOpenCustomer: (clientId) {
              cubit.setTab(WalletTab.directory);
              cubit.selectCustomer(clientId);
            },
            onBatchRefund: () => _batchRefund(context, cubit),
          ),
        },
      ],
    );
  }

  Widget _buildDirectory(BuildContext context, WalletCubit cubit) {
    return MasterDetailLayout(
      masterFlex: 2,
      detailFlex: 3,
      placeholderTitle: 'اختر عميلاً لعرض محفظته',
      placeholderSubtitle:
          'كل حركة مالية تبدأ من عميل محدّد — لا توجد صفحة تسويات عامة، وهذا مقصود.',
      master: WalletDirectoryPanel(
        directory: state.directory,
        search: state.directorySearch,
        selectedClientId: state.selectedClientId,
        onSearch: cubit.searchDirectory,
        onSelect: cubit.selectCustomer,
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
      final path = await WalletStatementExportService.export(
        rows: state.ledger.rows,
        overview: state.overview,
      );
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
