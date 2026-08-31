import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_cap_notice.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_segmented_bar.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/finance_entities.dart';
import 'finance_format.dart';

/// The single control that scopes the whole module.
///
/// It lives in the module header, on the same line as the section switcher,
/// because every section answers the same question for the same window — a
/// per-section date picker is how two figures on one screen end up meaning two
/// different periods.
///
/// The presets are deliberately of two kinds. **Rolling** windows (آخر ٧ أيام)
/// answer "how are we doing", **calendar** windows (هذا الشهر، الشهر الماضي)
/// answer "close the month", and an owner reconciling against paper needs the
/// second. Offering only the first is why the module used to disagree with the
/// books on every day except the 30th.
///
/// It is one [DashboardSegmentedBar] rather than the eight loose `ChoiceChip`s
/// it used to be: eight independently-shaped chips read as eight switches that
/// could each be on or off, and they cost the module a full row of its own
/// plus a tinted restatement box underneath. One group of segments says
/// "exactly one of these" in a third of the height, and what the choice
/// *resolved to* is now one quiet line ([FinanceWindowNote]) under the toolbar
/// instead of a panel.
class FinancePeriodBar extends StatelessWidget {
  /// The resolved window — bounds, label and what the comparison is against.
  final FinanceWindow window;

  final ValueChanged<FinancePeriod> onSelected;

  /// Applies an operator-chosen range. Receives two days, inclusive.
  final void Function(DateTime start, DateTime end) onCustomRange;

  const FinancePeriodBar({
    super.key,
    required this.window,
    required this.onSelected,
    required this.onCustomRange,
  });

  /// Everything except [FinancePeriod.custom], which is an action rather than a
  /// segment because it has to ask a question before it can mean anything.
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
    final isCustom = window.period == FinancePeriod.custom;

    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DashboardSegmentedBar<FinancePeriod>(
          dense: true,
          tone: DashboardSegmentTone.raised,
          // A custom range is not one of the presets, so while it is in force
          // no segment may look chosen. Pointing `selected` at a value the bar
          // does not contain is how that is said.
          selected: isCustom ? FinancePeriod.custom : window.period,
          onSelected: onSelected,
          segments: [
            for (final period in _presets)
              DashboardSegment(value: period, label: period.label),
          ],
        ),
        DashboardSegmentedAction(
          icon: Icons.date_range_rounded,
          label: isCustom ? window.label : FinancePeriod.custom.label,
          active: isCustom,
          tooltip: 'اختر تاريخي بداية ونهاية',
          onPressed: () => _pick(context),
        ),
      ],
    );
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
    onCustomRange(picked.start, picked.end);
  }
}

/// What the chosen period actually resolved to, and everything else the reader
/// needs to trust the figures above it — in one quiet wrapping line.
///
/// A segment that says "هذا الشهر" is a name, not a boundary. On the 3rd of the
/// month the difference between that and "آخر ٣٠ يوم" is most of the revenue,
/// and an owner reading a figure has to be able to see which one produced it.
/// This used to be a tinted panel with the same four facts in it; a panel makes
/// a footnote look like a finding.
class FinanceWindowNote extends StatelessWidget {
  const FinanceWindowNote({
    super.key,
    required this.window,
    required this.loadedAt,
    this.capReached = false,
  });

  final FinanceWindow window;
  final DateTime loadedAt;
  final bool capReached;

  @override
  Widget build(BuildContext context) {
    final start = window.start;
    final bounds = start == null
        ? 'كل الحركات المسجلة حتى ${FinanceFormat.date(window.end)}'
        : 'من ${FinanceFormat.date(start)} إلى ${FinanceFormat.date(window.end)}';

    return _NoteLine(
      leading: _WindowChip(label: window.label),
      items: [
        bounds,
        if (window.previous != null)
          'المقارنة مع ${window.previousLabel}'
        else
          'لا توجد فترة سابقة للمقارنة',
        if (window.isComplete)
          'فترة مكتملة'
        else if (window.isBounded)
          'الفترة ما زالت جارية',
        'آخر تحديث ${FinanceFormat.time(loadedAt)}',
        'التحقق من إثباتات الدفع يتم في قسم الحجوزات',
      ],
      trailing: capReached
          ? const DashboardCapNotice(
              rowCap: FinanceLedger.rowCap,
              noun: 'معاملة',
              // The period switcher above already narrows the window, so
              // pointing at the filters would be telling the operator to do
              // what they are looking at.
              hint: '',
            )
          : null,
    );
  }
}

/// The resolved window's name, marked so the eye finds the scope first and the
/// detail second.
class _WindowChip extends StatelessWidget {
  const _WindowChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = DashboardColors.accentInk(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_available_rounded, size: 14, color: accent),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: accent,
          ),
        ),
      ],
    );
  }
}

/// A wrapping row of muted facts, separated by dots.
///
/// Each fact stays its own `Text` on purpose: joining them into one string
/// would let a long window label push a short, load-bearing sentence off the
/// end of the line, and the separators would break across rows with nothing
/// beside them.
class _NoteLine extends StatelessWidget {
  const _NoteLine({required this.leading, required this.items, this.trailing});

  final Widget leading;
  final List<String> items;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: DashboardColors.mutedInk(context));
    final faint = DashboardColors.faintInk(context);

    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        leading,
        for (final item in items) ...[
          Text('·', style: TextStyle(color: faint)),
          Text(item, style: muted),
        ],
        ?trailing,
      ],
    );
  }
}
