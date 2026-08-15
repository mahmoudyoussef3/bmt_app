import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/complaint.dart';
import '../cubit/tickets_cubit.dart';
import '../cubit/tickets_state.dart';
import 'tickets_shared_widgets.dart';
import 'ticket_details_dialog.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';

/// How the queue is ordered. The support queue's real question is "what is about
/// to breach", which is why SLA is the default sort rather than creation date.
enum _TicketSort { ticketNumber, client, priority, sla, createdAt }

class TicketsTable extends StatefulWidget {
  final TicketsLoaded state;
  const TicketsTable({super.key, required this.state});

  @override
  State<TicketsTable> createState() => _TicketsTableState();
}

class _TicketsTableState extends State<TicketsTable> {
  static const _pageSize = 12;

  int _page = 0;
  _TicketSort _sort = _TicketSort.sla;
  OpsSort _direction = OpsSort.asc;

  /// Column index → sort key. Indices that are not sortable are absent.
  static const _sortColumns = <int, _TicketSort>{
    0: _TicketSort.ticketNumber,
    2: _TicketSort.client,
    4: _TicketSort.priority,
    5: _TicketSort.sla,
    8: _TicketSort.createdAt,
  };

  int? get _sortColumnIndex {
    for (final entry in _sortColumns.entries) {
      if (entry.value == _sort) return entry.key;
    }
    return null;
  }

  void _onSort(int index) {
    final key = _sortColumns[index];
    if (key == null) return;
    setState(() {
      if (_sort == key) {
        _direction = _direction == OpsSort.asc ? OpsSort.desc : OpsSort.asc;
      } else {
        _sort = key;
        _direction = OpsSort.asc;
      }
      _page = 0;
    });
  }

  List<SupportTicket> _sorted(List<SupportTicket> tickets) {
    final sorted = [...tickets];
    // A ticket with no SLA clock sorts last however the column is pointed — it is
    // never the thing the operator is looking for when they sort by SLA.
    int compare(SupportTicket a, SupportTicket b) => switch (_sort) {
      _TicketSort.ticketNumber => a.ticketNumber.compareTo(b.ticketNumber),
      _TicketSort.client => a.clientName.compareTo(b.clientName),
      _TicketSort.priority => a.priority.index.compareTo(b.priority.index),
      _TicketSort.createdAt => a.createdAt.compareTo(b.createdAt),
      _TicketSort.sla => switch ((a.slaDueAt, b.slaDueAt)) {
        (null, null) => 0,
        (null, _) => 1,
        (_, null) => -1,
        (final x?, final y?) => x.compareTo(y),
      },
    };

    sorted.sort((a, b) {
      if (_sort == _TicketSort.sla) {
        if (a.slaDueAt == null || b.slaDueAt == null) return compare(a, b);
      }
      final result = compare(a, b);
      return _direction == OpsSort.asc ? result : -result;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TicketsCubit>();
    final filtered = _sorted(widget.state.filteredTickets);

    final start = (_page * _pageSize).clamp(0, filtered.length);
    final end = (start + _pageSize).clamp(0, filtered.length);
    final pageItems = filtered.sublist(start, end);

    final errorTint = context.status(AppStatusTone.error).tint;

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
      rows: [for (final t in pageItems) _row(t)],
      onRowTap: [
        for (final t in pageItems)
          () {
            cubit.selectTicket(t.id);
            showDialog<void>(
              context: context,
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: const TicketDetailsDialog(),
              ),
            );
          },
      ],
      rowTints: [for (final t in pageItems) t.slaBreached ? errorTint : null],
      total: filtered.length,
      currentPage: _page,
      pageSize: _pageSize,
      onPageChanged: (p) => setState(() => _page = p),
      sortColumnIndex: _sortColumnIndex,
      sortDirection: _direction,
      onSort: _onSort,
      emptyState: _emptyState(context),
    );
  }

  Widget _emptyState(BuildContext context) {
    final state = widget.state;
    final isFiltered =
        state.searchQuery.isNotEmpty ||
        state.filterStatus != null ||
        state.filterPriority != null;

    if (isFiltered) {
      return DashboardEmptyState(
        icon: Icons.search_off_rounded,
        title: 'لا توجد تذاكر مطابقة',
        message:
            'لا توجد تذكرة تطابق البحث أو الفلاتر الحالية. جرّب توسيع الفلاتر '
            'أو مسح البحث.',
        action: OutlinedButton.icon(
          onPressed: () => context.read<TicketsCubit>().clearFilters(),
          icon: const Icon(Icons.filter_alt_off_rounded),
          label: const Text('مسح الفلاتر'),
        ),
      );
    }

    return const DashboardEmptyState(
      icon: DashboardIcons.tickets,
      title: 'لا توجد شكاوى',
      message:
          'لم يرسل أي عميل شكوى أو طلب دعم بعد. التذاكر التي يفتحها العملاء من '
          'تطبيق الركاب تظهر هنا فور وصولها.',
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
      _SlaBadge(ticket: t),
      Text(
        t.assignedAgentName ?? '—',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(t.category, maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(_formatDate(t.createdAt), maxLines: 1),
    ];
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}/$month/$day';
  }
}

class _SlaBadge extends StatefulWidget {
  const _SlaBadge({required this.ticket});
  final SupportTicket ticket;

  @override
  State<_SlaBadge> createState() => _SlaBadgeState();
}

class _SlaBadgeState extends State<_SlaBadge> {
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

    final remaining = ticket.slaDueAt!.difference(DateTime.now());
    if (remaining.isNegative) {
      return _badge('متأخرة', error.tint, error.ink, bold: true);
    }

    final label = remaining.inHours > 0
        ? 'متبقٍ ${remaining.inHours} س ${remaining.inMinutes.remainder(60)} د'
        : 'متبقٍ ${remaining.inMinutes} د';
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
