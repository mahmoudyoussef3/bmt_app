import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/finance_money_model.dart';
import 'finance_common.dart';
import 'finance_format.dart';

/// The three statements, and the equation that proves them (§7).
///
/// This panel exists because one number was wrong. Reporting a single "net
/// revenue" and treating a wallet balance as revenue or as cash produced a
/// report that said an office which ran two trips and kept 300 EGP had earned
/// nothing. Revenue, cash and liability are three different questions, and each
/// is simple only once it stops trying to be the other two.
///
/// The identity line at the bottom is not decoration. Finance asserts it on
/// every load, and if it does not balance to the piastre the module says so
/// rather than displaying a plausible wrong number.
class FinanceMoneyStatementsPanel extends StatelessWidget {
  const FinanceMoneyStatementsPanel({
    super.key,
    required this.statements,
    required this.periodLabel,
  });

  final FinanceMoneyStatements statements;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);

    return DashboardPanel(
      sectionId: DashboardSectionIds.financeStatements,
      icon: Icons.account_balance_rounded,
      title: 'القوائم الثلاث',
      subtitle:
          'الإيراد والنقدية والالتزامات — ثلاثة أرقام مستقلة، $periodLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardKpiGrid(
            maxColumns: 4,
            children: [
              DashboardKpiCard(
                label: 'صافي الإيراد',
                value: FinanceFormat.money(statements.revenue),
                detail: 'ما بِيع فعلاً، مطروحًا منه المرتجعات',
                icon: Icons.sell_rounded,
                color: palette.positive,
              ),
              DashboardKpiCard(
                label: 'النقدية المحصّلة',
                value: FinanceFormat.money(statements.cash),
                detail: 'ما دخل الخزينة فعلاً بعد المرتجعات النقدية',
                icon: Icons.savings_rounded,
                color: palette.active,
              ),
              DashboardKpiCard(
                label: 'التزامات المحفظة',
                value: FinanceFormat.money(statements.liabilityEnd),
                // The correction, said in the label: this is not money the
                // office earned, it is money it owes back as service.
                detail: 'أرصدة لدى العملاء — التزام وليس إيرادًا',
                icon: Icons.account_balance_wallet_rounded,
                color: palette.warning,
              ),
              DashboardKpiCard(
                label: 'تكلفة الحوافز',
                value: FinanceFormat.money(statements.promotionalCost),
                detail: 'كاش باك وإضافات — تُعرض بجانب الإيراد لا تُخصم منه',
                icon: Icons.card_giftcard_rounded,
                color: palette.accent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          FinanceFigureRow(
            label: 'المساهمة بعد الحوافز',
            value: FinanceFormat.money(statements.contributionAfterIncentives),
            emphasised: true,
          ),
          FinanceFigureRow(
            label: 'التزامات أول الفترة',
            value: FinanceFormat.money(statements.liabilityStart),
          ),
          FinanceFigureRow(
            label: 'التغير في الالتزامات',
            value: FinanceFormat.money(statements.deltaLiability),
            valueColor: statements.deltaLiability >= 0
                ? palette.warning
                : palette.positive,
          ),
          FinanceFigureRow(
            label: 'مرتجعات خرجت نقدًا',
            value: '− ${FinanceFormat.money(statements.cashOut)}',
            valueColor: palette.negative,
          ),
          const SizedBox(height: AppSpacing.medium),
          _IdentityBanner(statements: statements),
        ],
      ),
    );
  }
}

/// Either "the books balance" or the exact size of the gap. Never silence.
class _IdentityBanner extends StatelessWidget {
  const _IdentityBanner({required this.statements});

  final FinanceMoneyStatements statements;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = DashboardChartPalette.of(context);
    final holds = statements.identityHolds;
    final tint = holds ? palette.positive : scheme.error;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: tint.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: tint.withAlpha(110)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            holds ? Icons.check_circle_rounded : Icons.error_rounded,
            color: tint,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holds
                      ? 'معادلة الضبط متوازنة'
                      : 'معادلة الضبط غير متوازنة — راجع البيانات قبل الاعتماد',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'النقدية الداخلة − الخارجة = الإيراد − الحوافز + التغير في الالتزامات',
                  style: text.bodySmall,
                ),
                Text(
                  '${FinanceFormat.money(statements.cashIn)} − '
                  '${FinanceFormat.money(statements.cashOut)} = '
                  '${FinanceFormat.money(statements.revenue)} − '
                  '${FinanceFormat.money(statements.promotionalCost)} + '
                  '${FinanceFormat.money(statements.deltaLiability)}'
                  '${holds ? '' : '  ·  الفارق ${FinanceFormat.moneyPrecise(statements.identityGap)}'}',
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
