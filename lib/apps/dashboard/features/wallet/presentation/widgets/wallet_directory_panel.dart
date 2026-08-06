import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../../domain/entities/wallet.dart';
import '../../domain/entities/wallet_vocabulary.dart';
import 'wallet_format.dart';

/// Surface 1 — the customer directory.
///
/// This is the module's foundation rather than a nicety: the dashboard has no
/// customer entity at all (§1.1), so "who are my customers and what do I owe
/// them" had no home before this list. It is also the only entry point to money
/// movement — §8.1 rejects a standalone adjustments page outright, because a
/// context-free "adjust a balance" form is precisely the control weakness this
/// module exists to remove.
class WalletDirectoryPanel extends StatelessWidget {
  const WalletDirectoryPanel({
    super.key,
    required this.directory,
    required this.search,
    required this.selectedClientId,
    required this.onSearch,
    required this.onSelect,
  });

  final WalletDirectoryPage directory;
  final String search;
  final String? selectedClientId;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return DashboardPanel(
      icon: DashboardIcons.users,
      title: 'العملاء',
      subtitle: directory.total == directory.rows.length
          ? '${WalletFormat.count(directory.total)} عميل'
          : 'عرض ${WalletFormat.count(directory.rows.length)} من ${WalletFormat.count(directory.total)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DebouncedSearchField(
            initialValue: search,
            hintText: 'بحث بالاسم أو رقم الهاتف',
            onChanged: onSearch,
          ),
          const SizedBox(height: AppSpacing.medium),
          if (directory.rows.isEmpty)
            DashboardEmptyState(
              icon: DashboardIcons.users,
              title: search.trim().isEmpty
                  ? 'لا يوجد عملاء بعد'
                  : 'لا توجد نتائج مطابقة',
              message: search.trim().isEmpty
                  ? 'يظهر هنا كل عميل حجز أو اشترك مع مكتبك.'
                  : 'جرّب اسمًا أو رقم هاتف آخر.',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 620),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: directory.rows.length,
                itemBuilder: (context, index) {
                  final entry = directory.rows[index];
                  return _DirectoryTile(
                    entry: entry,
                    now: now,
                    selected: entry.clientId == selectedClientId,
                    onTap: () => onSelect(entry.clientId),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DirectoryTile extends StatelessWidget {
  const _DirectoryTile({
    required this.entry,
    required this.now,
    required this.selected,
    required this.onTap,
  });

  final WalletDirectoryEntry entry;
  final DateTime now;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final palette = DashboardChartPalette.of(context);
    final radius = BorderRadius.circular(AppTokens.radiusSmall);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Material(
        color: selected
            ? scheme.primary.withAlpha(20)
            : DashboardColors.nested(context),
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? scheme.primary.withAlpha(120)
                    : DashboardColors.border(context),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.displayName,
                              style: text.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (entry.walletStatus == WalletStatus.frozen) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.ac_unit_rounded,
                              size: 14,
                              color: palette.active,
                            ),
                          ],
                          // A waiting request is surfaced in the list, not only
                          // on the detail screen: an operator scanning the
                          // directory must be able to see where the queue is.
                          if (entry.pendingRefunds > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: palette.warning.withAlpha(38),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${entry.pendingRefunds} طلب',
                                style: text.labelSmall?.copyWith(
                                  color: palette.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.phone.isEmpty ? '—' : entry.phone,
                        style: text.labelSmall?.copyWith(
                          color: DashboardColors.mutedInk(context),
                        ),
                      ),
                      Text(
                        WalletFormat.age(entry.lastActivityAt, now),
                        style: text.labelSmall?.copyWith(
                          color: DashboardColors.faintInk(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Text(
                  WalletFormat.money(entry.balance),
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: entry.balance > 0
                        ? palette.active
                        : DashboardColors.faintInk(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
