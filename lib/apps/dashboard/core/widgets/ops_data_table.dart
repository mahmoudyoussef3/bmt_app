import 'package:flutter/material.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
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
    // A [Wrap] rather than a `Row` with a `Spacer`.
    //
    // The row version overflowed at the console's own narrowest declared
    // breakpoint (360px) and got worse with every step of text scale, because
    // nothing in it could yield: two unbounded `Text`s and two fixed 48px
    // buttons in a lane that does not grow. Adding `Flexible` + ellipsis would
    // have stopped the overflow by *deleting the numbers* — and the totals are
    // the entire content of this bar.
    //
    // Wrapping lets the counts drop onto their own lines instead, so a narrow
    // window or 1.6× text costs vertical space rather than information. At
    // normal widths everything still sits on one line, `spaceBetween` holding
    // the total at the start edge and the controls at the end, which is what
    // the row produced.
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      // The bar must fill the row for `spaceBetween` to mean anything: a Wrap
      // under a Column's loose constraints shrink-wraps to its children and
      // then centres the lot, which reads as an accident at desktop widths.
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.xSmall,
          children: [
            Text('الإجمالي $total'),
            _NumberedPager(
              currentPage: currentPage,
              pages: pages,
              onPageChanged: onPageChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact numbered pager — first, last, a window around the current page and
/// an ellipsis between — replacing the plain prev/next icon pair. A page
/// number is a destination the operator can jump straight to; two arrows only
/// ever answer "one step from here".
class _NumberedPager extends StatelessWidget {
  const _NumberedPager({
    required this.currentPage,
    required this.pages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int pages;
  final ValueChanged<int> onPageChanged;

  /// Which zero-indexed pages to render as buttons, `null` standing in for an
  /// ellipsis. Always includes the first and last page and a window of up to
  /// two neighbours on each side of [currentPage].
  List<int?> _slots() {
    if (pages <= 7) return [for (var i = 0; i < pages; i++) i];

    final slots = <int>{0, pages - 1};
    for (var i = currentPage - 1; i <= currentPage + 1; i++) {
      if (i > 0 && i < pages - 1) slots.add(i);
    }
    final sorted = slots.toList()..sort();
    final result = <int?>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) result.add(null);
      result.add(sorted[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'السابق',
          onPressed: currentPage == 0
              ? null
              : () => onPageChanged(currentPage - 1),
          icon: const Icon(DashboardIcons.paginationPrevious, size: 18),
          visualDensity: VisualDensity.compact,
        ),
        for (final slot in _slots())
          if (slot == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('…'),
            )
          else
            _PageNumberButton(
              page: slot,
              selected: slot == currentPage,
              onTap: () => onPageChanged(slot),
            ),
        IconButton(
          tooltip: 'التالي',
          onPressed: currentPage >= pages - 1
              ? null
              : () => onPageChanged(currentPage + 1),
          icon: const Icon(DashboardIcons.paginationNext, size: 18),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(6);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: selected
            ? DashboardColors.accentFill(context)
            : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: selected ? null : onTap,
          borderRadius: radius,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: Text(
                '${page + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? DashboardColors.onHero(context)
                      : DashboardColors.mutedInk(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
