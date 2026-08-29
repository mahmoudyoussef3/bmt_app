import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_pager.dart';
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

  /// Tap handler per row, parallel to [rows]. A row whose entry is null (or when
  /// the whole list is omitted) stays inert, so existing call sites are unchanged.
  final List<VoidCallback?>? onRowTap;

  /// Background tint per row, parallel to [rows] — for flagging a row that needs
  /// attention (a breached SLA, an overdue payment). Hover still wins over it.
  final List<Color?>? rowTints;

  /// Replaces the plain [emptyLabel] text when the table has no rows — pass a
  /// [DashboardEmptyState] to say *why* it is empty and what to do about it.
  final Widget? emptyState;

  /// Search + quick filters + advanced-filter trigger, rendered inside the same
  /// card above the sticky header row. The EWT table modules (Trips, Routes,
  /// Bookings, …) all share this shape — one bordered panel holding the search
  /// bar, the column header and the rows — rather than a separate toolbar card
  /// floating above the table.
  final Widget? toolbar;

  /// Wording for the running total in the pagination bar. Defaults to the bare
  /// "الإجمالي 45"; pass the module's own noun ("الإجمالي 45 اشتراك") so the
  /// table and the card list it falls back to read the same.
  final String? totalLabel;

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
    this.onRowTap,
    this.rowTints,
    this.emptyState,
    this.toolbar,
    this.totalLabel,
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
              if (toolbar != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                    vertical: AppSpacing.small,
                  ),
                  child: toolbar,
                ),
                Divider(
                  height: 1,
                  color: DashboardColors.tableDivider(context),
                ),
              ],
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
                          child:
                              emptyState ??
                              Text(emptyLabel, textAlign: TextAlign.center),
                        )
                      else
                        ...rows.asMap().entries.expand((entry) sync* {
                          if (entry.key > 0) {
                            yield Divider(
                              height: 1,
                              color: DashboardColors.tableDivider(context),
                            );
                          }
                          yield _HoverableOpsBodyRow(
                            columns: columns,
                            cells: entry.value,
                            onTap: entry.key < (onRowTap?.length ?? 0)
                                ? onRowTap![entry.key]
                                : null,
                            tint: entry.key < (rowTints?.length ?? 0)
                                ? rowTints![entry.key]
                                : null,
                          );
                        }),
                    ],
                  ),
                ),
              ),
              DashboardPagerBar(
                totalLabel: totalLabel ?? 'الإجمالي $total',
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
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
      color: DashboardColors.mutedInk(context),
    );
    return Container(
      color: DashboardColors.tableHeader(context),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
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

class _HoverableOpsBodyRow extends StatefulWidget {
  final List<OpsColumn> columns;
  final List<Widget> cells;
  final VoidCallback? onTap;
  final Color? tint;

  const _HoverableOpsBodyRow({
    required this.columns,
    required this.cells,
    this.onTap,
    this.tint,
  });

  @override
  State<_HoverableOpsBodyRow> createState() => _HoverableOpsBodyRowState();
}

class _HoverableOpsBodyRowState extends State<_HoverableOpsBodyRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final row = MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _isHovered
            ? DashboardColors.tableRowHover(context)
            : (widget.tint ?? Colors.transparent),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: widget.cells
              .asMap()
              .entries
              .map(
                (e) => _OpsCell(
                  flex: e.key < widget.columns.length
                      ? widget.columns[e.key].flex
                      : 1,
                  trailingGap: e.key < widget.cells.length - 1,
                  alignment:
                      e.key < widget.columns.length &&
                          widget.columns[e.key].numeric
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: e.value,
                ),
              )
              .toList(),
        ),
      ),
    );

    if (widget.onTap == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: row,
    );
  }
}
