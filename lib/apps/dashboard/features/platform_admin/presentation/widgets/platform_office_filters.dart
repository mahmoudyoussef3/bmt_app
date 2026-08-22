import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../../domain/entities/platform_analytics.dart';
import '../../domain/entities/platform_office_filter.dart';

/// Search and the two status axes, kept as separate controls.
///
/// They are separate because they answer different questions and a platform
/// admin asks them separately: "which offices are suspended" is an operational
/// question, "which offices are waiting to be published" is a marketplace one.
/// One combined dropdown would have to invent rows like "active but withdrawn"
/// and would make either question unreliable to ask.
class PlatformOfficeFilters extends StatelessWidget {
  const PlatformOfficeFilters({
    super.key,
    required this.filter,
    required this.resultCount,
    required this.totalCount,
    required this.onSearch,
    required this.onStatus,
    required this.onListingStatus,
    required this.onActivity,
    required this.onSort,
    required this.onClear,
    this.hasMetrics = true,
  });

  final PlatformOfficeFilter filter;
  final int resultCount;
  final int totalCount;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String?> onListingStatus;
  final ValueChanged<ActivityLevel?> onActivity;
  final ValueChanged<PlatformOfficeSort> onSort;
  final VoidCallback onClear;

  /// Whether analytics has loaded. The activity facet and the metric-based
  /// sorts are hidden without it rather than shown inert: a control that
  /// silently does nothing is worse than one that is not there yet.
  final bool hasMetrics;

  static const _statusOptions = <String, String>{
    'active': 'نشط',
    'paused': 'متوقف مؤقتًا',
    'suspended': 'موقوف',
    'archived': 'مؤرشف',
  };

  static const _listingOptions = <String, String>{
    'draft': 'قيد التجهيز',
    'listed': 'معروض في السوق',
    'unlisted': 'مسحوب من السوق',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFiltered = !filter.isEmpty;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: DebouncedSearchField(
                  // Remounts (with the field's own fresh controller) whenever
                  // the query changes from outside — the "مسح عوامل التصفية"
                  // button included — so an external clear is reflected here
                  // too, not just in the filtered list.
                  key: ValueKey('platform-office-search-${filter.query}'),
                  initialValue: filter.query,
                  hintText: 'ابحث باسم المكتب أو المعرّف أو المالك',
                  onChanged: onSearch,
                ),
              ),
              _FilterDropdown(
                label: 'الحالة التشغيلية',
                value: filter.status,
                options: _statusOptions,
                onChanged: onStatus,
              ),
              _FilterDropdown(
                label: 'حالة العرض في السوق',
                value: filter.listingStatus,
                options: _listingOptions,
                onChanged: onListingStatus,
              ),
              if (hasMetrics) ...[
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<ActivityLevel?>(
                    initialValue: filter.activity,
                    isDense: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'النشاط التجاري',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<ActivityLevel?>(
                        value: null,
                        child: Text('الكل'),
                      ),
                      for (final level in ActivityLevel.values)
                        DropdownMenuItem<ActivityLevel?>(
                          value: level,
                          child: Text(level.label),
                        ),
                    ],
                    onChanged: onActivity,
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<PlatformOfficeSort>(
                    initialValue: filter.sort,
                    isDense: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'الترتيب',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final sort in PlatformOfficeSort.values)
                        DropdownMenuItem(value: sort, child: Text(sort.label)),
                    ],
                    onChanged: (sort) {
                      if (sort != null) onSort(sort);
                    },
                  ),
                ),
              ],
              if (isFiltered)
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('مسح عوامل التصفية'),
                ),
            ],
          ),
          if (isFiltered) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              resultCount == 0
                  ? 'لا توجد مكاتب مطابقة من إجمالي $totalCount'
                  : 'عرض $resultCount من $totalCount مكتب',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String?>(
        initialValue: value,
        isDense: true,
        // Without this the selected label lays out at its natural width inside
        // a 200px box and the row overflows — «مسحوبة من السوق» is wider than
        // the field it is chosen in. Expanded, it ellipsizes instead.
        isExpanded: true,
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<String?>(value: null, child: Text('الكل')),
          for (final entry in options.entries)
            DropdownMenuItem<String?>(
              value: entry.key,
              child: Text(entry.value),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
