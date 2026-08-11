import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/wallet.dart';
import '../cubit/wallet_state.dart';
import 'wallet_format.dart';

/// The module header's KPI strip (§8.2).
///
/// The first tile is a **liability**, and it is labelled as one. That word is
/// the whole correction in §2.2: a wallet balance is neither revenue nor cash —
/// it is money the office holds and owes back as service. Showing it beside
/// revenue without saying so is how an office comes to believe it earned money
/// it has already promised away.
class WalletOverviewStrip extends StatelessWidget {
  const WalletOverviewStrip({
    super.key,
    required this.overview,
    required this.onOpenRefunds,
  });

  final WalletOverview overview;
  final VoidCallback onOpenRefunds;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: DashboardKpiGrid(
        maxColumns: 5,
        children: [
          DashboardKpiCard(
            label: 'الأرصدة القائمة',
            value: WalletFormat.money(overview.outstandingBalance),
            detail:
                '${WalletFormat.count(overview.fundedWalletCount)} محفظة بها رصيد',
            icon: Icons.account_balance_wallet_rounded,
            color: palette.active,
          ),
          DashboardKpiCard(
            label: 'كاش باك ممنوح',
            value: WalletFormat.money(overview.cashbackTotal),
            detail: 'تكلفة حوافز — لا تُخصم من الإيراد',
            icon: Icons.card_giftcard_rounded,
            color: palette.accent,
          ),
          DashboardKpiCard(
            label: 'مرتجعات منفّذة',
            value: WalletFormat.money(overview.refundTotal),
            detail:
                'منها ${WalletFormat.money(overview.refundWalletTotal)} إلى المحافظ',
            icon: Icons.assignment_return_rounded,
            color: palette.warning,
          ),
          DashboardKpiCard(
            label: 'تسويات يدوية',
            value: WalletFormat.money(
              overview.creditTotal + overview.debitTotal,
            ),
            detail:
                '+${WalletFormat.money(overview.creditTotal)} · −${WalletFormat.money(overview.debitTotal)}',
            icon: Icons.tune_rounded,
            color: palette.neutral,
          ),
          DashboardKpiCard(
            label: 'طلبات معلّقة',
            value: WalletFormat.count(overview.pendingRefundCount),
            detail: overview.pendingRefundCount == 0
                ? 'لا شيء ينتظر قرارًا'
                : 'بقيمة ${WalletFormat.money(overview.pendingRefundAmount)}',
            icon: Icons.pending_actions_rounded,
            color: overview.pendingRefundCount > 0
                ? palette.warning
                : palette.neutral,
            
            onTap: onOpenRefunds,
            tapHint: 'افتح طلبات الاسترداد',
          ),
        ],
      ),
    );
  }
}

/// The module's tab bar. Three surfaces, one screen — the directory (with its
/// detail pane), the office-wide ledger, and the refund queue.
class WalletTabBar extends StatelessWidget {
  const WalletTabBar({
    super.key,
    required this.current,
    required this.onChanged,
    required this.openRefundCount,
  });

  final WalletTab current;
  final ValueChanged<WalletTab> onChanged;
  final int openRefundCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        0,
        AppSpacing.medium,
        AppSpacing.medium,
      ),
      child: Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.small,
        children: [
          for (final tab in WalletTab.values)
            ChoiceChip(
              selected: tab == current,
              onSelected: (_) => onChanged(tab),
              avatar: tab == WalletTab.refunds && openRefundCount > 0
                  ? CircleAvatar(
                      backgroundColor: scheme.error,
                      child: Text(
                        '$openRefundCount',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: scheme.onError,
                        ),
                      ),
                    )
                  : null,
              label: Text(tab.label),
            ),
        ],
      ),
    );
  }
}
