import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../domain/entities/licensing_catalog.dart';
import 'licensing_widgets.dart';

/// What the operator picked: a plan and the cycle it is billed on.
typedef AssignPlanChoice = ({String planId, String cycle});

/// Puts an office on a plan.
///
/// It replaces a `SimpleDialog` of bare list tiles that could only ever assign
/// a *monthly* cycle — the yearly price was printed on the plan card and
/// unreachable from the one screen that assigns plans. Here the plan is a card
/// you can compare, the cycle is a choice, and the plan the office is already
/// on is marked so a re-assignment is never a guess.
Future<AssignPlanChoice?> showAssignPlanDialog(
  BuildContext context, {
  required List<LicensingPlan> plans,
  required String officeName,
  String currentPlanKey = '',
  String? currentCycle,
}) {
  return showDialog<AssignPlanChoice>(
    context: context,
    builder: (context) => _AssignPlanDialog(
      plans: plans,
      officeName: officeName,
      currentPlanKey: currentPlanKey,
      currentCycle: currentCycle,
    ),
  );
}

class _AssignPlanDialog extends StatefulWidget {
  const _AssignPlanDialog({
    required this.plans,
    required this.officeName,
    required this.currentPlanKey,
    required this.currentCycle,
  });

  final List<LicensingPlan> plans;
  final String officeName;
  final String currentPlanKey;
  final String? currentCycle;

  @override
  State<_AssignPlanDialog> createState() => _AssignPlanDialogState();
}

class _AssignPlanDialogState extends State<_AssignPlanDialog> {
  String? _planId;
  late String _cycle = switch (widget.currentCycle) {
    'yearly' => 'yearly',
    _ => 'monthly',
  };

  LicensingPlan? get _selected =>
      widget.plans.where((p) => p.id == _planId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plans = [...widget.plans]
      ..sort((a, b) {
        final byStatus = (a.status == 'active' ? 0 : 1).compareTo(
          b.status == 'active' ? 0 : 1,
        );
        return byStatus != 0 ? byStatus : a.sortOrder.compareTo(b.sortOrder);
      });
    final selected = _selected;

    return AlertDialog(
      title: Text('باقة «${widget.officeName}»'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                
                'التعيين يبدأ مدة جديدة فورًا، ويعيد حساب صلاحيات المكتب من قيم '
                'الباقة الجديدة. الاستثناءات القائمة تبقى كما هي.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              if (plans.isEmpty)
                Text(
                  'لا توجد باقة قابلة للتعيين. أنشئ باقة ثم انشرها أولًا.',
                  style: theme.textTheme.bodyMedium,
                )
              else
                for (final plan in plans)
                  _PlanOption(
                    plan: plan,
                    cycle: _cycle,
                    selected: plan.id == _planId,
                    isCurrent: plan.key == widget.currentPlanKey,
                    onTap: () => setState(() => _planId = plan.id),
                  ),
              const SizedBox(height: AppSpacing.medium),
              Row(
                children: [
                  Text(
                    'دورة الفوترة',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'monthly', label: Text('شهرية')),
                      ButtonSegment(value: 'yearly', label: Text('سنوية')),
                    ],
                    selected: {_cycle},
                    onSelectionChanged: (s) => setState(() => _cycle = s.first),
                  ),
                ],
              ),
              if (selected != null &&
                  _cycle == 'yearly' &&
                  selected.priceYearly == null) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  'لا سعر سنوي معلن على «${selected.nameAr}» — ستُعامَل المدة '
                  'كعقد بسعر تفاوضي.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _planId == null
              ? null
              : () => Navigator.of(
                  context,
                ).pop((planId: _planId!, cycle: _cycle)),
          child: const Text('تعيين'),
        ),
      ],
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.plan,
    required this.cycle,
    required this.selected,
    required this.isCurrent,
    required this.onTap,
  });

  final LicensingPlan plan;
  final String cycle;
  final bool selected;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppTokens.radiusSmall);
    final price = cycle == 'yearly' ? plan.priceYearly : plan.priceMonthly;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withAlpha(20)
                  : DashboardColors.well(context),
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? scheme.primary.withAlpha(150)
                    : DashboardColors.border(context),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected
                      ? scheme.primary
                      : DashboardColors.mutedInk(context),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              plan.nameAr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: AppSpacing.small),
                            StatusChip(
                              label: 'الباقة الحالية',
                              color: scheme.secondary.withAlpha(24),
                              textColor: scheme.secondary,
                            ),
                          ],
                          if (plan.status != 'active') ...[
                            const SizedBox(width: AppSpacing.xSmall),
                            StatusChip(
                              label: plan.statusLabelAr,
                              color: scheme.tertiary.withAlpha(24),
                              textColor: scheme.tertiary,
                            ),
                          ],
                        ],
                      ),
                      if (plan.taglineAr.trim().isNotEmpty)
                        Text(
                          plan.taglineAr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: DashboardColors.mutedInk(context),
                          ),
                        ),
                      if (plan.trialDays > 0)
                        Text(
                          'تجربة ${plan.trialDays} يوم',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: DashboardColors.mutedInk(context),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price == null
                          ? 'سعر تفاوضي'
                          : licensingMoney(price, plan.currency),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          DashboardIcons.platformOffices,
                          size: 12,
                          color: DashboardColors.mutedInk(context),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${plan.officeCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: DashboardColors.mutedInk(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
