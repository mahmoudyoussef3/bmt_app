import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// The one toolbar shape every list module in المبيعات wears.
///
/// Three regions, always in this order, so an operator moving between
/// الحجوزات, الاشتراكات and العملاء keeps the same muscle memory:
///
///  1. **[tabs]** — the queue strip, when the module has queues. A directory
///     that is not worked as a queue passes null and the strip is absent
///     rather than faked.
///  2. **The pinned row** — [search] and [sort]. These never fold. Search is
///     the control used on almost every visit, and a sort the operator cannot
///     see is a sort they will not use; الاشتراكات used to bury both inside the
///     collapsed panel, so its list looked unsortable and unsearchable until
///     you opened «التصفية».
///  3. **[filters]** — everything worth a second click, behind one fold that
///     remembers itself per [sectionId].
///
/// What is folded still says what it is holding: [filterSummary] renders as
/// the collapsed chip row, because a filter the operator forgot they set is how
/// a partial list gets read as the whole list. [onClearFilters] sits in the
/// section's own header so it is reachable **without** unfolding — the modules
/// each used to hide their reset button at the end of the filter row, which is
/// the one place you cannot reach while the row is closed.
class DashboardFilterBar extends StatelessWidget {
  const DashboardFilterBar({
    super.key,
    required this.sectionId,
    required this.search,
    required this.filters,
    required this.filterSummary,
    required this.activeFilterCount,
    required this.onClearFilters,
    this.tabs,
    this.sort,
  });

  /// Session memory key for the fold. Use a [DashboardSectionIds] constant.
  final String sectionId;

  /// The queue strip. Pass a [DashboardQueueTabBar], or null for a module with
  /// no queues.
  final Widget? tabs;

  /// The always-visible search input, usually a `DebouncedSearchField`.
  final Widget search;

  /// The always-visible ordering control. Null for a list whose order the
  /// operator does not choose.
  final Widget? sort;

  /// The foldable filter controls — normally a `Wrap` of fields.
  final Widget filters;

  /// What the folded row is still doing, in the operator's own words.
  final List<String> filterSummary;

  /// Drives the reset button's badge. The sort is not a filter: it changes the
  /// order, not the population, so it must not be counted here.
  final int activeFilterCount;

  final VoidCallback onClearFilters;

  /// Below this a 240px sort control beside a search field leaves neither
  /// usable, so the pinned row stacks.
  static const double _stackBelow = 720;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tabs != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.medium,
                AppSpacing.medium,
                AppSpacing.medium,
                AppSpacing.medium,
              ),
              child: tabs,
            ),
            Divider(height: 1, color: DashboardColors.divider(context)),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.medium,
              AppSpacing.medium,
              AppSpacing.medium,
              0,
            ),
            child: _PinnedRow(search: search, sort: sort),
          ),
          DashboardCollapsibleSection.bare(
            sectionId: sectionId,
            icon: Icons.filter_alt_outlined,
            title: 'التصفية',
            initiallyExpanded: false,
            collapsedSummary: DashboardSectionSummary(items: filterSummary),
            actions: [
              if (activeFilterCount > 0)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text('مسح التصفية ($activeFilterCount)'),
                ),
            ],
            child: filters,
          ),
        ],
      ),
    );
  }
}

class _PinnedRow extends StatelessWidget {
  const _PinnedRow({required this.search, required this.sort});

  final Widget search;
  final Widget? sort;

  @override
  Widget build(BuildContext context) {
    final ordering = sort;
    if (ordering == null) return search;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < DashboardFilterBar._stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: AppSpacing.small),
              ordering,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: search),
            const SizedBox(width: AppSpacing.small),
            SizedBox(width: 240, child: ordering),
          ],
        );
      },
    );
  }
}

/// The responsive lane [DashboardFilterBar.filters] is normally built from.
///
/// Every field gets the same width at a given console width — one column
/// below 720, two up to 1080, a fixed 230 beyond — so the filter rows of two
/// modules opened one after the other line up instead of each picking their own
/// grid. [trailing] is for controls that size to their own content (a chip, a
/// toggle) and would look wrong stretched to a field's width.
class DashboardFilterFields extends StatelessWidget {
  const DashboardFilterFields({
    super.key,
    required this.fields,
    this.trailing = const [],
  });

  final List<Widget> fields;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = constraints.maxWidth;
        final compact = full < 720;
        final double fieldWidth = compact
            ? full
            : full < 1080
            ? (full - AppSpacing.small) / 2
            : 230;

        return Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final field in fields)
              SizedBox(width: fieldWidth, child: field),
            ...trailing,
          ],
        );
      },
    );
  }
}

/// One filter field, identical in every module.
///
/// [values] carries its own "الكل" member — pass it first and let [labelOf]
/// name it — rather than each call site hand-writing a null [DropdownMenuItem]
/// above a mapped list. That is what let the three modules drift into three
/// spellings of "no filter" and two different ideas of whether a filter field
/// carries an icon.
///
/// A field with nothing to choose from renders disabled and says why through
/// [emptyHint], instead of showing an empty dropdown that looks broken.
class DashboardFilterDropdown<T> extends StatelessWidget {
  const DashboardFilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
    this.icon,
    this.enabled = true,
    this.emptyHint,
  });

  final String label;
  final T value;

  /// Every option, including the "all" member.
  final List<T> values;

  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final IconData? icon;
  final bool enabled;

  /// Shown in place of the dropdown when [values] holds nothing to choose
  /// between — "لا توجد رحلات بعد".
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    final hint = emptyHint;
    if (hint != null && values.length <= 1) {
      return _DisabledFilterField(label: label, icon: icon, hint: hint);
    }

    return DropdownButtonFormField<T>(
      initialValue: values.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        isDense: true,
      ),
      items: [
        for (final item in values)
          DropdownMenuItem<T>(
            value: item,
            child: Text(labelOf(item), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: enabled
          ? (selected) {
              // A dropdown reports null when it is cleared, which none of these
              // can be — every set includes its own "الكل" member. The type test
              // also admits null for a nullable T, where null *is* "الكل".
              if (selected is T) onChanged(selected);
            }
          : null,
    );
  }
}

/// The ordering control, pinned beside the search field in every module.
///
/// A dropdown rather than a popup menu, so it reads as the peer of the filter
/// fields it sits above and states its current key without being opened.
/// [ascending] adds the direction toggle for the modules whose sort has one;
/// a module whose every key has one sensible direction leaves it null rather
/// than offering "the customer who has spent least".
class DashboardSortControl<T> extends StatelessWidget {
  const DashboardSortControl({
    super.key,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
    this.label = 'الترتيب',
    this.ascending,
    this.onToggleDirection,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final bool? ascending;
  final VoidCallback? onToggleDirection;

  @override
  Widget build(BuildContext context) {
    final dropdown = DashboardFilterDropdown<T>(
      label: label,
      icon: Icons.swap_vert_rounded,
      value: value,
      values: values,
      labelOf: labelOf,
      onChanged: onChanged,
    );

    final direction = ascending;
    if (direction == null) return dropdown;

    return Row(
      children: [
        Expanded(child: dropdown),
        const SizedBox(width: AppSpacing.xSmall),
        IconButton(
          tooltip: direction ? 'تصاعدي — اضغط للعكس' : 'تنازلي — اضغط للعكس',
          onPressed: onToggleDirection,
          icon: Icon(
            direction
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 18,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _DisabledFilterField extends StatelessWidget {
  const _DisabledFilterField({
    required this.label,
    required this.icon,
    required this.hint,
  });

  final String label;
  final IconData? icon;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        isDense: true,
        enabled: false,
      ),
      child: Text(
        hint,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: DashboardColors.mutedInk(context),
        ),
      ),
    );
  }
}
