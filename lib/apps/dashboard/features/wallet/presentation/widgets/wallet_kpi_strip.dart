import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/core/theme/colors.dart';

import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';
import '../models/wallet_views.dart';
import 'wallet_format.dart';

/// The header's stat tiles — **four per tab, and they change with the tab**.
///
/// The strip used to be one office-wide row that stayed put while the tab under
/// it changed, so two of its five tiles were unrelated to whatever list was on
/// screen and the list's own numbers ("how many movements did this filter
/// match?") had nowhere to be. Now the header answers the question the tab it
/// crowns is asking.
///
/// Four tiles rather than five: the grid is one full row at every console width
/// that way, and it is the same shape المبيعات wears next door. All three sets
/// use `emphasized` tiles at `itemExtent: 132` with the tone's `accent` on the
/// icon, so switching tabs changes the numbers and never the furniture.
///
/// **A tile is a shortcut only where the predicate behind it is exact.** The
/// activity and refund tiles filter their own lists, because their counts and
/// those lists come from the same query. The directory tiles do not: their
/// figures are office-wide totals from `office_wallet_overview`, while the list
/// under them is the first page the directory RPC returned — tapping one would
/// promise a narrowing it cannot deliver. The one exception is «طلبات معلّقة»,
/// which hands off to the tab that owns those rows rather than filtering here.
class WalletKpiStrip extends StatelessWidget {
  const WalletKpiStrip({super.key, required this.state});

  final WalletLoadedState state;

  /// What the folded header still says, per tab.
  static List<String> summaryFor(WalletLoadedState state) {
    final overview = state.overview;
    return switch (state.tab) {
      WalletTab.directory => [
        if (overview.pendingRefundCount > 0)
          'بانتظار استرداد ${WalletFormat.count(overview.pendingRefundCount)}',
        'أرصدة قائمة ${WalletFormat.money(overview.outstandingBalance)}',
        'محافظ ${WalletFormat.count(overview.walletCount)}',
      ],
      WalletTab.activity => [
        'حركات ${WalletFormat.count(state.ledger.total)}',
        'إضافات ${WalletFormat.money(state.ledger.sumCredit)}',
        'خصومات ${WalletFormat.money(state.ledger.sumDebit)}',
      ],
      WalletTab.refunds => [
        if (state.openRefundCount > 0)
          'بانتظار القرار ${WalletFormat.count(state.openRefundCount)}',
        'منفّذة ${WalletFormat.count(state.refundCountOf(WalletRefundScope.settled))}',
        'مرفوضة ${WalletFormat.count(state.refundCountOf(WalletRefundScope.refused))}',
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WalletCubit>();

    return DashboardKpiGrid(
      maxColumns: 4,
      itemExtent: 132,
      children: switch (state.tab) {
        WalletTab.directory => _directoryTiles(context, cubit),
        WalletTab.activity => _activityTiles(context, cubit),
        WalletTab.refunds => _refundTiles(context, cubit),
      },
    );
  }

  List<Widget> _directoryTiles(BuildContext context, WalletCubit cubit) {
    final overview = state.overview;
    return [
      // First, and named as a liability. A wallet balance is money the office
      // holds and owes back as service — printing it beside revenue without
      // saying so is how an office comes to believe it earned money it has
      // already promised away.
      _tile(
        context,
        label: 'الأرصدة القائمة',
        value: WalletFormat.money(overview.outstandingBalance),
        detail:
            'التزام على المكتب — '
            '${WalletFormat.count(overview.fundedWalletCount)} محفظة بها رصيد',
        icon: DashboardIcons.walletActive,
        tone: AppStatusTone.info,
      ),
      _tile(
        context,
        label: 'محافظ العملاء',
        value: WalletFormat.count(overview.walletCount),
        detail: overview.frozenCount == 0
            ? 'لا توجد محافظ مجمّدة'
            : 'منها ${WalletFormat.count(overview.frozenCount)} مجمّدة',
        icon: DashboardIcons.customers,
        tone: AppStatusTone.neutral,
      ),
      _tile(
        context,
        label: 'كاش باك وتسويات',
        value: WalletFormat.money(overview.promotionalCost),
        detail: 'تكلفة حوافز — تُقرأ بجانب الإيراد لا داخله',
        icon: DashboardIcons.referrals,
        tone: AppStatusTone.special,
      ),
      _tile(
        context,
        label: 'طلبات معلّقة',
        value: WalletFormat.count(overview.pendingRefundCount),
        detail: overview.pendingRefundCount == 0
            ? 'لا شيء ينتظر قرارًا'
            : 'بقيمة ${WalletFormat.money(overview.pendingRefundAmount)}',
        icon: Icons.pending_actions_rounded,
        tone: overview.pendingRefundCount > 0
            ? AppStatusTone.warning
            : AppStatusTone.neutral,
        onTap: () => cubit.setTab(WalletTab.refunds),
        hint: 'افتح طلبات الاسترداد',
      ),
    ];
  }

  List<Widget> _activityTiles(BuildContext context, WalletCubit cubit) {
    final page = state.ledger;
    final filters = state.filters;
    return [
      _tile(
        context,
        label: 'حركات مطابقة',
        value: WalletFormat.count(page.total),
        detail: filters.isEmpty
            ? 'كل الحركات على محافظ العملاء'
            : 'ضمن التصفية الحالية',
        icon: DashboardIcons.activity,
        tone: AppStatusTone.info,
      ),
      // Both directions are server predicates on the same query that produced
      // these sums, so each tile opens exactly the rows it counted.
      _tile(
        context,
        label: 'إضافات',
        value: WalletFormat.money(page.sumCredit),
        detail: 'رصيد أُضيف لحساب العملاء',
        icon: Icons.south_west_rounded,
        tone: AppStatusTone.success,
        onTap: () => cubit.applyFilters(filters.copyWith(creditsOnly: true)),
        hint: 'اعرض الإضافات فقط',
      ),
      _tile(
        context,
        label: 'خصومات',
        value: WalletFormat.money(page.sumDebit),
        detail: 'رصيد خُصم من حساب العملاء',
        icon: Icons.north_east_rounded,
        tone: AppStatusTone.error,
        onTap: () => cubit.applyFilters(filters.copyWith(creditsOnly: false)),
        hint: 'اعرض الخصومات فقط',
      ),
      _tile(
        context,
        label: 'صافي الأثر',
        value: WalletFormat.signed(page.net),
        detail: 'أثر الفترة على الالتزام تجاه العملاء',
        icon: DashboardIcons.trend,
        tone: AppStatusTone.special,
      ),
    ];
  }

  List<Widget> _refundTiles(BuildContext context, WalletCubit cubit) {
    final filters = state.refundFilters;
    final open = state.refundCountOf(WalletRefundScope.open);
    final openAmount = state.refundQueue
        .where(WalletRefundScope.open.matches)
        .fold<double>(0, (sum, refund) => sum + refund.effectiveAmount);
    final settled = state.refundQueue
        .where(WalletRefundScope.settled.matches)
        .toList();
    final fromClient = state.refundQueue.where((r) => r.fromClient).length;

    return [
      _tile(
        context,
        label: 'بانتظار القرار',
        value: WalletFormat.count(open),
        detail: open == 0
            ? 'الطابور فارغ'
            : 'بقيمة ${WalletFormat.money(openAmount)}',
        icon: Icons.pending_actions_rounded,
        tone: open > 0 ? AppStatusTone.warning : AppStatusTone.neutral,
        onTap: open == 0
            ? null
            : () => cubit.applyRefundFilters(
                filters.copyWith(scope: WalletRefundScope.open),
              ),
        hint: 'اعرض الطلبات المفتوحة',
      ),
      _tile(
        context,
        label: 'مرتجعات منفّذة',
        value: WalletFormat.count(settled.length),
        detail:
            'بقيمة '
            '${WalletFormat.money(settled.fold<double>(0, (sum, r) => sum + r.effectiveAmount))}',
        icon: Icons.assignment_turned_in_outlined,
        tone: AppStatusTone.success,
        onTap: settled.isEmpty
            ? null
            : () => cubit.applyRefundFilters(
                filters.copyWith(scope: WalletRefundScope.settled),
              ),
        hint: 'اعرض المرتجعات المنفّذة',
      ),
      _tile(
        context,
        label: 'مرفوضة أو ملغاة',
        value: WalletFormat.count(
          state.refundCountOf(WalletRefundScope.refused),
        ),
        detail: 'طلبات أُغلقت دون صرف',
        icon: Icons.do_not_disturb_on_outlined,
        tone: AppStatusTone.error,
        onTap: state.refundCountOf(WalletRefundScope.refused) == 0
            ? null
            : () => cubit.applyRefundFilters(
                filters.copyWith(scope: WalletRefundScope.refused),
              ),
        hint: 'اعرض الطلبات المرفوضة',
      ),
      _tile(
        context,
        label: 'من تطبيق العميل',
        value: WalletFormat.count(fromClient),
        detail: 'طلبات رفعها العملاء بأنفسهم',
        icon: Icons.phone_iphone_rounded,
        tone: AppStatusTone.special,
        onTap: fromClient == 0
            ? null
            : () => cubit.applyRefundFilters(
                filters.copyWith(
                  scope: WalletRefundScope.all,
                  source: WalletRefundSource.client,
                ),
              ),
        hint: 'اعرض طلبات العملاء',
      ),
    ];
  }

  Widget _tile(
    BuildContext context, {
    required String label,
    required String value,
    required String detail,
    required IconData icon,
    required AppStatusTone tone,
    VoidCallback? onTap,
    String? hint,
  }) {
    return DashboardKpiCard(
      label: label,
      value: value,
      detail: detail,
      icon: icon,
      // The tone's `accent`, not its `ink`: a tile's fill is near-white, and
      // `ink` on it reads as black type rather than as a status.
      color: DashboardColors.status(context, tone).accent,
      emphasized: true,
      onTap: onTap,
      tapHint: onTap == null ? null : hint,
    );
  }
}
