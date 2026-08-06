import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_kpi_card.dart';
import '../../../../core/widgets/dashboard_module_header.dart';
import '../../../../core/widgets/dashboard_panel.dart';
import '../widgets/licensing_scaffold.dart';
import '../widgets/licensing_widgets.dart';

/// الاستخدام — consumption against limits, across every office.
///
/// Two kinds of meter share this screen and they are not the same thing:
///
///   * **stock** — how many exist right now. Deleting a driver returns the seat.
///     Counted at read time, so it is self-healing and cannot drift.
///   * **flow**  — how many happened this period. Deleting the trip does NOT
///     return the quota, or an office on a 100-trip plan would run 1,000 by
///     deleting each one when it finished.
///
/// The screen labels which is which, because "why did my number not go down"
/// is the first question this data produces.
class PlatformUsageScreen extends StatelessWidget {
  const PlatformUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LicensingScreenFrame(
      builder: (context, state) {
        final rows = state.usage;
        final overLimits = rows.fold<int>(
          0,
          (sum, row) => sum + row.overLimits.length,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardModuleHeader(
              icon: DashboardIcons.usage,
              title: 'الاستخدام',
              subtitle: 'استهلاك كل مكتب مقابل حدود باقته.',
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: DashboardKpiGrid(
                  children: [
                    DashboardKpiCard(
                      label: 'مكاتب',
                      value: '${rows.length}',
                      icon: DashboardIcons.platformOffices,
                    ),
                    DashboardKpiCard(
                      label: 'حدود متجاوَزة',
                      value: '$overLimits',
                      icon: DashboardIcons.attention,
                      detail: 'لا يُحذف شيء — يُمنع الإنشاء الجديد فقط',
                    ),
                    DashboardKpiCard(
                      label: 'وضع التطبيق',
                      value: switch (state.settings.enforcementMode) {
                        'off' => 'معطّل',
                        'shadow' => 'ظل',
                        _ => 'مفعّل',
                      },
                      icon: DashboardIcons.settings,
                      detail: state.settings.modeLabelAr,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Expanded(
              child: rows.isEmpty
                  ? const DashboardEmptyState(
                      icon: DashboardIcons.usage,
                      title: 'لا توجد بيانات استهلاك',
                    )
                  : ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.medium),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return DashboardPanel(
                          icon: DashboardIcons.platformOffices,
                          title: row.officeName,
                          subtitle: row.planKey.isEmpty
                              ? 'بلا باقة'
                              : 'باقة ${row.planKey}',
                          trailing: row.overLimits.isEmpty
                              ? null
                              : StatusChip(
                                  label: 'تجاوز ${row.overLimits.length}',
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.error.withAlpha(24),
                                  textColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                          child: Column(
                            children: [
                              for (final metric in row.metrics)
                                UsageBar(
                                  label:
                                      '${metric.nameAr}'
                                      '${metric.meterKind == 'flow' ? ' (هذا الشهر)' : ''}',
                                  used: metric.used,
                                  limit: metric.limit,
                                  unit: metric.unitAr,
                                  dense: true,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              'عدّاد المخزون يُحسب لحظيًا من الصفوف القائمة، فحذف صف يعيد الحصة. '
              'عدّاد التدفّق يتراكم خلال الشهر ولا يعود بالحذف.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
          ],
        );
      },
    );
  }
}
