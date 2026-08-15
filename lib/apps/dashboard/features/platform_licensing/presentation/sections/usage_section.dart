import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../domain/entities/office_license.dart';
import '../widgets/licensing_layout.dart';
import '../widgets/licensing_widgets.dart';

/// الاستخدام — one office's consumption against its limits.
///
/// This used to be a destination of its own: a scroll of one panel per office,
/// each repeating the meters the licence screen already drew for the office the
/// operator had open. Two screens showing the same numbers is two screens to
/// keep in sync and one more row in the sidebar, so the cross-office view is
/// gone and its meters live here, inside the office they belong to. The
/// platform-wide question it used to answer — *who is over a limit* — is
/// answered better by the «تجاوزت حدًّا» signal on the licence list, which names
/// the offices and the metrics rather than making the operator scan for red.
///
/// Two kinds of meter share this panel and they are not the same thing:
///
///   * **stock** — how many exist right now. Deleting a driver returns the seat.
///     Counted at read time, so it is self-healing and cannot drift.
///   * **flow**  — how many happened this period. Deleting the trip does NOT
///     return the quota, or an office on a 100-trip plan would run 1,000 by
///     deleting each one when it finished.
///
/// The panel labels which is which, because "why did my number not go down" is
/// the first question this data produces.
class OfficeUsagePanel extends StatelessWidget {
  const OfficeUsagePanel({super.key, required this.detail, required this.row});

  final OfficeLicenseDetail detail;

  /// The platform usage row for this office, when the console has one. It
  /// carries `meterKind`, which the entitlement limits do not — so it is
  /// preferred, and the limits are the fallback that keeps the panel honest on
  /// a console that has not finished loading usage yet.
  final OfficeUsageRow? row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = row?.metrics ?? const <UsageMetric>[];
    final limits = detail.entitlements.limits;

    if (metrics.isEmpty && limits.isEmpty) {
      return const DashboardEmptyState(
        icon: DashboardIcons.usage,
        title: 'لا توجد حدود على هذه الباقة',
        message: 'كل عدّاد في هذه الباقة بلا سقف، فلا شيء يُقاس هنا.',
      );
    }

    final overLimits = metrics.isEmpty
        ? detail.overLimits.length
        : row!.overLimits.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LicensingStatStrip(
          stats: [
            LicensingStat(
              icon: DashboardIcons.usage,
              value: '${metrics.isEmpty ? limits.length : metrics.length}',
              label: 'عدّاد محدود',
            ),
            LicensingStat(
              icon: DashboardIcons.attention,
              value: '$overLimits',
              label: 'حد متجاوَز',
              color: overLimits > 0 ? scheme.error : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        if (metrics.isNotEmpty)
          for (final metric in metrics)
            UsageBar(
              label:
                  '${metric.nameAr}'
                  '${metric.meterKind == 'flow' ? ' (هذا الشهر)' : ''}',
              used: metric.used,
              limit: metric.limit,
              unit: metric.unitAr,
              dense: true,
            )
        else
          for (final limit in limits)
            UsageBar(
              label: limit.nameAr,
              used: limit.used ?? 0,
              limit: limit.limit,
              unit: limit.unitAr,
              dense: true,
            ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          'عدّاد المخزون يُحسب لحظيًا من الصفوف القائمة، فحذف صف يعيد الحصة. '
          'عدّاد التدفّق يتراكم خلال الشهر ولا يعود بالحذف. تجاوز الحد لا يحذف '
          'شيئًا — يمنع الإنشاء الجديد فقط.',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: DashboardColors.mutedInk(context),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
