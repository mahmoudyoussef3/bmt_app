import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// Sort direction for an [OpsColumn].
enum OpsSort { none, asc, desc }

/// Declarative column for [OpsDataTable]. `flex` drives proportional width
/// (replacing the equal-width / fixed-150px paradigms).
class OpsColumn {
  final String label;
  final int flex;
  final bool numeric;
  final bool sortable;
  final double minWidth;

  const OpsColumn(
    this.label, {
    this.flex = 1,
    this.numeric = false,
    this.sortable = false,
    this.minWidth = 72,
  });
}

/// The single unified dashboard table: sticky header, proportional columns,
/// optional sort, integrated pagination, RTL-correct. Consolidates the three
/// legacy paradigms (Flutter DataTable / FleetTableShell / card lists).
class OpsDataTable extends StatelessWidget {
  final List<OpsColumn> columns;
  final List<List<Widget>> rows;
  final int total;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final int? sortColumnIndex;
  final OpsSort sortDirection;
  final ValueChanged<int>? onSort;
  final String emptyLabel;

  const OpsDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.total,
    required this.currentPage,
    required this.pageSize,
    required this.onPageChanged,
    this.sortColumnIndex,
    this.sortDirection = OpsSort.none,
    this.onSort,
    this.emptyLabel = 'لا توجد بيانات مطابقة',
  });

  @override
  Widget build(BuildContext context) {
    final pages = (total / pageSize).ceil().clamp(1, 9999);
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentMinWidth = columns.fold<double>(
          0,
          (sum, column) => sum + column.minWidth,
        );
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : contentMinWidth;
        final tableWidth = availableWidth < contentMinWidth
            ? contentMinWidth
            : availableWidth;

        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      _OpsHeaderRow(
                        columns: columns,
                        sortColumnIndex: sortColumnIndex,
                        sortDirection: sortDirection,
                        onSort: onSort,
                      ),
                      if (rows.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xLarge),
                          child: Text(emptyLabel),
                        )
                      else
                        // Rows are pre-paginated by the host, so we render the
                        // current page inline under unbounded scroll parents.
                        ...rows.asMap().entries.expand((entry) sync* {
                          if (entry.key > 0) {
                            yield Divider(
                              height: 1,
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withAlpha(60),
                            );
                          }
                          yield _OpsBodyRow(
                            columns: columns,
                            cells: entry.value,
                          );
                        }),
                    ],
                  ),
                ),
              ),
              _OpsPaginationBar(
                total: total,
                currentPage: currentPage,
                pages: pages,
                onPageChanged: onPageChanged,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OpsCell extends StatelessWidget {
  const _OpsCell({
    required this.flex,
    required this.child,
    required this.trailingGap,
    required this.alignment,
  });

  final int flex;
  final Widget child;
  final bool trailingGap;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          end: trailingGap ? AppSpacing.small : 0,
        ),
        child: Align(alignment: alignment, child: child),
      ),
    );
  }
}

class _OpsHeaderRow extends StatelessWidget {
  final List<OpsColumn> columns;
  final int? sortColumnIndex;
  final OpsSort sortDirection;
  final ValueChanged<int>? onSort;

  const _OpsHeaderRow({
    required this.columns,
    required this.sortColumnIndex,
    required this.sortDirection,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold);
    return Container(
      color: scheme.surfaceContainerHighest.withAlpha(90),
      padding: const EdgeInsets.all(AppSpacing.small),
      child: Row(
        children: columns.asMap().entries.map((e) {
          final col = e.value;
          final active = sortColumnIndex == e.key;
          final header = Row(
            mainAxisAlignment: col.numeric
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(child: Text(col.label, style: style)),
              if (col.sortable)
                Icon(
                  active && sortDirection == OpsSort.desc
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 14,
                  color: active ? scheme.primary : scheme.onSurfaceVariant,
                ),
            ],
          );
          return _OpsCell(
            flex: col.flex,
            trailingGap: e.key < columns.length - 1,
            alignment: col.numeric
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: col.sortable && onSort != null
                ? InkWell(onTap: () => onSort!(e.key), child: header)
                : header,
          );
        }).toList(),
      ),
    );
  }
}

class _OpsBodyRow extends StatelessWidget {
  final List<OpsColumn> columns;
  final List<Widget> cells;

  const _OpsBodyRow({required this.columns, required this.cells});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: cells
            .asMap()
            .entries
            .map(
              (e) => _OpsCell(
                flex: e.key < columns.length ? columns[e.key].flex : 1,
                trailingGap: e.key < cells.length - 1,
                alignment: e.key < columns.length && columns[e.key].numeric
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: e.value,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _OpsPaginationBar extends StatelessWidget {
  final int total;
  final int currentPage;
  final int pages;
  final ValueChanged<int> onPageChanged;

  const _OpsPaginationBar({
    required this.total,
    required this.currentPage,
    required this.pages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.small),
      child: Row(
        children: [
          Text('الإجمالي $total'),
          const Spacer(),
          Text('صفحة ${currentPage + 1} من $pages'),
          const SizedBox(width: AppSpacing.small),
          IconButton(
            tooltip: 'السابق',
            onPressed: currentPage == 0
                ? null
                : () => onPageChanged(currentPage - 1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          IconButton(
            tooltip: 'التالي',
            onPressed: currentPage >= pages - 1
                ? null
                : () => onPageChanged(currentPage + 1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ],
      ),
    );
  }
}
