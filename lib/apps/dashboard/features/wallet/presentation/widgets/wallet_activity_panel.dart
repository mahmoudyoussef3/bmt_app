import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../../domain/entities/wallet_transaction.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import 'wallet_format.dart';
import 'wallet_ledger_entry_tile.dart';

/// Surface 3 — office-wide financial activity.
///
/// Answers "what did my staff do this week". The filter set (§8.3) is
/// deliberately wider than a list needs to be pretty: **category**, **source**
/// and **has-reversal** are each there because an operator would otherwise
/// answer that question by scrolling.
///
/// Every predicate is evaluated server-side in one query, so the count in the
/// header and the rows below it can never disagree about what "filtered" meant.
class WalletActivityPanel extends StatelessWidget {
  const WalletActivityPanel({
    super.key,
    required this.page,
    required this.filters,
    required this.loading,
    required this.canExport,
    required this.onFiltersChanged,
    required this.onExport,
  });

  final WalletLedgerPage page;
  final WalletLedgerFilters filters;
  final bool loading;

  /// Export is owner-only (§6): a full customer financial history in a
  /// spreadsheet is a data-exfiltration surface, and it is the one read that
  /// leaves the audited system.
  final bool canExport;

  final ValueChanged<WalletLedgerFilters> onFiltersChanged;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      icon: Icons.query_stats_rounded,
      title: 'الحركات المالية',
      subtitle: loading
          ? 'جارٍ التحميل…'
          : '${WalletFormat.count(page.total)} حركة · '
                'إضافات ${WalletFormat.money(page.sumCredit)} · '
                'خصومات ${WalletFormat.money(page.sumDebit)}',
      trailing: canExport
          ? TextButton.icon(
              onPressed: page.rows.isEmpty ? null : onExport,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('تصدير'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterBar(filters: filters, onChanged: onFiltersChanged),
          const SizedBox(height: AppSpacing.medium),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.large),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (page.rows.isEmpty)
            DashboardEmptyState(
              icon: Icons.query_stats_rounded,
              title: filters.isEmpty
                  ? 'لا توجد حركات مالية بعد'
                  : 'لا توجد حركات مطابقة للفلاتر',
              message: filters.isEmpty
                  ? 'تظهر هنا كل حركة على محافظ عملاء المكتب.'
                  : 'وسّع نطاق البحث أو أزل بعض الفلاتر.',
              action: filters.isEmpty
                  ? null
                  : TextButton.icon(
                      onPressed: () =>
                          onFiltersChanged(const WalletLedgerFilters()),
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                      label: const Text('إزالة كل الفلاتر'),
                    ),
            )
          else
            Column(
              children: [
                for (final entry in page.rows)
                  WalletLedgerEntryTile(entry: entry, showCustomer: true),
                if (page.total > page.rows.length)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.small),
                    child: Text(
                      // Say so rather than truncate silently: an operator
                      // reconciling a figure must know the list is partial.
                      'يتم عرض أحدث ${WalletFormat.count(page.rows.length)} حركة '
                      'من ${WalletFormat.count(page.total)}. ضيّق الفلاتر للوصول لحركات أقدم.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: DashboardColors.mutedInk(context),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filters, required this.onChanged});

  final WalletLedgerFilters filters;
  final ValueChanged<WalletLedgerFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DebouncedSearchField(
            initialValue: filters.search ?? '',
            hintText: 'بحث باسم العميل أو الهاتف أو رقم الحجز أو السبب',
            onChanged: (value) => onChanged(filters.copyWith(search: value)),
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              for (final kind in WalletKind.active)
                FilterChip(
                  label: Text(kind.label),
                  selected: filters.kinds.contains(kind),
                  onSelected: (selected) => onChanged(
                    filters.copyWith(
                      kinds: {
                        ...filters.kinds,
                        if (selected) kind,
                      }..removeWhere((k) => !selected && k == kind),
                    ),
                  ),
                ),
              const _Divider(),
              FilterChip(
                label: const Text('إضافات فقط'),
                selected: filters.creditsOnly == true,
                selectedColor: palette.positive.withAlpha(40),
                onSelected: (selected) => onChanged(
                  selected
                      ? filters.copyWith(creditsOnly: true)
                      : filters.copyWith(clearDirection: true),
                ),
              ),
              FilterChip(
                label: const Text('خصومات فقط'),
                selected: filters.creditsOnly == false,
                selectedColor: palette.negative.withAlpha(40),
                onSelected: (selected) => onChanged(
                  selected
                      ? filters.copyWith(creditsOnly: false)
                      : filters.copyWith(clearDirection: true),
                ),
              ),
              const _Divider(),
              FilterChip(
                label: const Text('بها تصحيح'),
                // The first thing anyone investigating a discrepancy wants.
                tooltip: 'العمليات المعكوسة والعمليات العكسية فقط',
                selected: filters.hasReversal == true,
                selectedColor: palette.warning.withAlpha(40),
                onSelected: (selected) => onChanged(
                  selected
                      ? filters.copyWith(hasReversal: true)
                      : filters.copyWith(clearReversal: true),
                ),
              ),
              const _Divider(),
              for (final source in const [
                WalletSource.dashboard,
                WalletSource.system,
                WalletSource.migration,
              ])
                FilterChip(
                  label: Text(source.label),
                  selected: filters.sources.contains(source),
                  onSelected: (selected) => onChanged(
                    filters.copyWith(
                      sources: {
                        ...filters.sources,
                        if (selected) source,
                      }..removeWhere((s) => !selected && s == source),
                    ),
                  ),
                ),
              if (!filters.isEmpty) ...[
                const _Divider(),
                ActionChip(
                  avatar: const Icon(Icons.filter_alt_off_rounded, size: 16),
                  label: const Text('مسح الفلاتر'),
                  onPressed: () => onChanged(const WalletLedgerFilters()),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          _DateRangeRow(filters: filters, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DateRangeRow extends StatelessWidget {
  const _DateRangeRow({required this.filters, required this.onChanged});

  final WalletLedgerFilters filters;
  final ValueChanged<WalletLedgerFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Preset chips rather than a date picker first: "this week" is what an
    // operator actually asks for, and the custom range is one tap further.
    final presets = <(String, DateTime?)>[
      ('الكل', null),
      ('اليوم', today),
      ('آخر ٧ أيام', today.subtract(const Duration(days: 7))),
      ('آخر ٣٠ يومًا', today.subtract(const Duration(days: 30))),
    ];

    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'الفترة',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: DashboardColors.mutedInk(context),
          ),
        ),
        for (final preset in presets)
          ChoiceChip(
            label: Text(preset.$1),
            selected: filters.from == preset.$2,
            onSelected: (_) => onChanged(
              preset.$2 == null
                  ? filters.copyWith(clearDates: true)
                  : filters.copyWith(from: preset.$2),
            ),
          ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: DashboardColors.divider(context),
    );
  }
}
