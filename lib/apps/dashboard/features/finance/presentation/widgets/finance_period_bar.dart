import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_cap_notice.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/finance_entities.dart';
import 'finance_format.dart';

/// The single control that scopes the whole module, and the sentence that says
/// what it resolved to.
///
/// It lives in the module header, above the tabs, because every tab answers the
/// same question for the same window — a per-tab date picker is how two figures
/// on one screen end up meaning two different periods.
///
/// The presets are deliberately of two kinds. **Rolling** windows (آخر ٧ أيام)
/// answer "how are we doing", **calendar** windows (هذا الشهر، الشهر الماضي)
/// answer "close the month", and an owner reconciling against paper needs the
/// second. Offering only the first is why the module used to disagree with the
/// books on every day except the 30th.
class FinancePeriodBar extends StatelessWidget {
  /// The resolved window — bounds, label and what the comparison is against.
  final FinanceWindow window;

  final ValueChanged<FinancePeriod> onSelected;

  /// Applies an operator-chosen range. Receives two days, inclusive.
  final void Function(DateTime start, DateTime end) onCustomRange;

  final DateTime loadedAt;
  final bool capReached;

  const FinancePeriodBar({
    super.key,
    required this.window,
    required this.onSelected,
    required this.onCustomRange,
    required this.loadedAt,
    this.capReached = false,
  });

  /// Everything except [FinancePeriod.custom], which is a button rather than a
  /// chip because it has to ask a question before it can mean anything.
  static const _presets = [
    FinancePeriod.today,
    FinancePeriod.week,
    FinancePeriod.thisMonth,
    FinancePeriod.lastMonth,
    FinancePeriod.month,
    FinancePeriod.quarter,
    FinancePeriod.all,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = window.period;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.small),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xSmall),
                  Text(
                    'فترة التقرير',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            for (final period in _presets)
              ChoiceChip(
                label: Text(period.label),
                selected: selected == period,
                avatar: selected == period
                    ? const Icon(Icons.check_rounded, size: 16)
                    : null,
                onSelected: (isSelected) {
                  if (isSelected) onSelected(period);
                },
              ),
            _CustomRangeButton(
              window: window,
              onPicked: onCustomRange,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        _WindowStatement(window: window),
        const SizedBox(height: AppSpacing.xSmall),
        Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.xSmall,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'آخر تحديث: ${FinanceFormat.time(loadedAt)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(
              'التحقق من إثباتات الدفع يتم في قسم الحجوزات',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (capReached)
              const DashboardCapNotice(
                rowCap: FinanceLedger.rowCap,
                noun: 'معاملة',
                // The period bar above already narrows the window, so pointing
                // at the filters would be telling the operator to do what they
                // are looking at.
                hint: '',
              ),
          ],
        ),
      ],
    );
  }
}

/// The window in dates and words: exactly which days are counted, and what the
/// comparison column is measured against.
///
/// A chip that says "هذا الشهر" is a name, not a boundary. On the 3rd of the
/// month the difference between that and "آخر ٣٠ يوم" is most of the revenue,
/// and an owner reading a figure has to be able to see which one produced it.
class _WindowStatement extends StatelessWidget {
  const _WindowStatement({required this.window});

  final FinanceWindow window;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final start = window.start;

    final bounds = start == null
        ? 'كل الحركات المسجلة حتى ${FinanceFormat.date(window.end)}'
        : 'من ${FinanceFormat.date(start)} إلى ${FinanceFormat.date(window.end)}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(16),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.primary.withAlpha(50)),
      ),
      child: Wrap(
        spacing: AppSpacing.medium,
        runSpacing: AppSpacing.xSmall,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: AppSpacing.xSmall),
              Text(
                window.label,
                style: text.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          Text(
            bounds,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (window.previous != null)
            Text(
              'المقارنة مع ${window.previousLabel}',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            )
          else
            Text(
              'لا توجد فترة سابقة للمقارنة',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          if (window.isComplete)
            Text(
              'فترة مكتملة',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            )
          else if (window.isBounded)
            Text(
              'الفترة ما زالت جارية',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _CustomRangeButton extends StatelessWidget {
  const _CustomRangeButton({required this.window, required this.onPicked});

  final FinanceWindow window;
  final void Function(DateTime start, DateTime end) onPicked;

  @override
  Widget build(BuildContext context) {
    final isActive = window.period == FinancePeriod.custom;
    final label = isActive ? window.label : FinancePeriod.custom.label;

    final button = isActive
        ? FilledButton.tonalIcon(
            onPressed: () => _pick(context),
            icon: const Icon(Icons.date_range_rounded, size: 18),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: () => _pick(context),
            icon: const Icon(Icons.date_range_rounded, size: 18),
            label: Text(label),
          );

    return button;
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final start = window.start;

    final picked = await showDateRangePicker(
      context: context,
      // The ledger itself is capped, so offering years the module cannot load
      // would be offering an empty answer. Three years back is well beyond the
      // cap for any office and keeps the picker honest about the horizon.
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year, now.month, now.day),
      currentDate: now,
      initialDateRange: start == null
          ? null
          : DateTimeRange(
              start: start,
              end: window.end.isAfter(now) ? now : window.end,
            ),
      helpText: 'اختر فترة التقرير',
      saveText: 'تطبيق',
    );

    if (picked == null) return;
    onPicked(picked.start, picked.end);
  }
}
