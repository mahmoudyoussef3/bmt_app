import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/complaint.dart';
import '../cubit/tickets_state.dart';
import '../models/ticket_sort.dart';
import 'tickets_shared_widgets.dart';
import 'tickets_format.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';

/// The support queue as an [OpsDataTable] — the same table shell الحجوزات,
/// الاشتراكات and العملاء render, so the الدعم section pages, sorts and reads
/// identically to المبيعات.
///
/// The ordering and the page live in [TicketsLoaded] and in the board above
/// this widget rather than in private state here: the toolbar's pinned sort
/// control and these column headers must drive one value, and the results
/// header above the rows has to know which slice is on screen.
class TicketsTable extends StatelessWidget {
  final TicketsLoaded state;

  /// The page of rows to draw, already ordered and sliced by the board.
  final List<SupportTicket> rows;

  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<TicketSort> onSort;
  final ValueChanged<SupportTicket> onOpen;

  const TicketsTable({
    super.key,
    required this.state,
    required this.rows,
    required this.pageIndex,
    required this.onPageChanged,
    required this.onSort,
    required this.onOpen,
  });

  /// Column index → sort key. Indices absent from this map are not sortable.
  static const _sortColumns = <int, TicketSort>{
    0: TicketSort.ticketNumber,
    2: TicketSort.client,
    4: TicketSort.priority,
    5: TicketSort.sla,
    8: TicketSort.createdAt,
  };

  int? get _sortColumnIndex {
    for (final entry in _sortColumns.entries) {
      if (entry.value == state.sort) return entry.key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final errorTint = context.status(AppStatusTone.error).tint;
    final total = state.visibleTickets.length;

    return OpsDataTable(
      columns: const [
        OpsColumn('رقم التذكرة', flex: 2, minWidth: 118, sortable: true),
        OpsColumn('العنوان', flex: 3, minWidth: 170),
        OpsColumn('العميل', flex: 2, minWidth: 130, sortable: true),
        OpsColumn('الحالة', flex: 2, minWidth: 124),
        OpsColumn('الأولوية', flex: 2, minWidth: 112, sortable: true),
        OpsColumn('المهلة', flex: 2, minWidth: 124, sortable: true),
        OpsColumn('المسؤول', flex: 2, minWidth: 118),
        OpsColumn('الفئة', flex: 2, minWidth: 112),
        OpsColumn('تاريخ الإنشاء', flex: 2, minWidth: 124, sortable: true),
      ],
      rows: [for (final t in rows) _row(t)],
      onRowTap: [for (final t in rows) () => onOpen(t)],
      rowTints: [for (final t in rows) t.slaBreached ? errorTint : null],
      total: total,
      totalLabel: 'الإجمالي ${TicketsFormat.count(total)} تذكرة',
      currentPage: pageIndex,
      pageSize: ticketsPageSize,
      onPageChanged: onPageChanged,
      sortColumnIndex: _sortColumnIndex,
      sortDirection: state.sortAscending ? OpsSort.asc : OpsSort.desc,
      onSort: (index) {
        final key = _sortColumns[index];
        if (key != null) onSort(key);
      },
    );
  }

  List<Widget> _row(SupportTicket t) {
    return [
      Text(
        t.ticketNumber,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(t.clientName, maxLines: 1, overflow: TextOverflow.ellipsis),
      StatusBadge(status: t.status),
      PriorityBadge(priority: t.priority),
      TicketSlaBadge(ticket: t),
      Text(
        t.assignedAgentName ?? '—',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(t.category, maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(TicketsFormat.date(t.createdAt), maxLines: 1),
    ];
  }
}

/// How much of the office's promise is left on a ticket, counted down live.
///
/// Public because the card layout the queue falls back to below
/// [kDashboardTableBreakpoint] shows the same badge — a deadline that reads one
/// way in the table and another on a card is the drift this pass removed.
class TicketSlaBadge extends StatefulWidget {
  const TicketSlaBadge({super.key, required this.ticket});

  final SupportTicket ticket;

  @override
  State<TicketSlaBadge> createState() => _TicketSlaBadgeState();
}

class _TicketSlaBadgeState extends State<TicketSlaBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.ticket.slaDueAt != null && !widget.ticket.slaBreached) {
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    if (ticket.slaDueAt == null) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final error = context.status(AppStatusTone.error);
    if (ticket.slaBreached) {
      return _badge('تجاوزت المهلة', error.tint, error.ink, bold: true);
    }

    final label = TicketsFormat.slaRemaining(ticket.slaDueAt, DateTime.now());
    if (label == null) {
      return _badge('متأخرة', error.tint, error.ink, bold: true);
    }

    final tone = ticket.isSlaNearBreach
        ? context.status(AppStatusTone.warning)
        : context.status(AppStatusTone.success);
    return _badge(label, tone.tint, tone.ink);
  }

  Widget _badge(String label, Color bg, Color fg, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xSmall,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
