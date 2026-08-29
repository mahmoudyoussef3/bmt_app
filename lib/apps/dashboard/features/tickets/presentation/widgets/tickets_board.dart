import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_pager.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_results_header.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/complaint.dart';
import '../cubit/tickets_cubit.dart';
import '../cubit/tickets_state.dart';
import 'ticket_details_dialog.dart';
import 'tickets_format.dart';
import 'tickets_shared_widgets.dart';
import 'tickets_table.dart';

/// The complaint queue: the shared results header, then the table at desktop
/// widths and a card list below [kDashboardTableBreakpoint] — both paged by the
/// same index, so narrowing the window never moves the agent to a different set
/// of rows.
///
/// Composed exactly like العملاء' directory and الاشتراكات' subscriber board,
/// which is what makes the الدعم section read as the same console: results
/// header → rows → one pagination bar, whichever layout is on screen.
class TicketsBoard extends StatefulWidget {
  const TicketsBoard({super.key, required this.state});

  final TicketsLoaded state;

  @override
  State<TicketsBoard> createState() => _TicketsBoardState();
}

class _TicketsBoardState extends State<TicketsBoard> {
  int _page = 0;

  @override
  void didUpdateWidget(covariant TicketsBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new filter or queue can shrink the result set out from under the
    // current page — land back on the last real page rather than an empty one.
    final maxPage = _pageCount - 1;
    if (_page > maxPage) _page = maxPage;
  }

  List<SupportTicket> get _ordered => widget.state.visibleTickets;

  int get _pageCount =>
      (_ordered.length / ticketsPageSize).ceil().clamp(1, 99999);

  List<SupportTicket> get _pageItems {
    final ordered = _ordered;
    final start = (_page * ticketsPageSize).clamp(0, ordered.length);
    final end = (start + ticketsPageSize).clamp(0, ordered.length);
    return ordered.sublist(start, end);
  }

  void _open(BuildContext context, SupportTicket ticket) {
    final cubit = context.read<TicketsCubit>();
    cubit.selectTicket(ticket.id);
    showDialog<void>(
      context: context,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const TicketDetailsDialog()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _pageItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResultsHeader(
          total: _ordered.length,
          page: _page,
          showing: rows.length,
        ),
        const SizedBox(height: AppSpacing.small),
        if (rows.isEmpty)
          // Bare, not inside an AppCard: DashboardEmptyState draws its own
          // bordered surface, and the two together read as a panel in a panel.
          _EmptyQueue(state: widget.state)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < kDashboardTableBreakpoint) {
                return _TicketCardList(
                  rows: rows,
                  total: _ordered.length,
                  page: _page,
                  pages: _pageCount,
                  onPageChanged: (page) => setState(() => _page = page),
                  onOpen: (ticket) => _open(context, ticket),
                );
              }
              return TicketsTable(
                state: widget.state,
                rows: rows,
                pageIndex: _page,
                onPageChanged: (page) => setState(() => _page = page),
                onSort: (sort) {
                  context.read<TicketsCubit>().setSort(sort);
                  setState(() => _page = 0);
                },
                onOpen: (ticket) => _open(context, ticket),
              );
            },
          ),
      ],
    );
  }
}

/// What this list is, and how much of it is on screen — the same strip every
/// other list module puts above its rows.
class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.total,
    required this.page,
    required this.showing,
  });

  final int total;
  final int page;
  final int showing;

  @override
  Widget build(BuildContext context) {
    final first = showing == 0 ? 0 : page * ticketsPageSize + 1;
    final last = first == 0 ? 0 : first + showing - 1;

    return DashboardResultsHeader(
      icon: DashboardIcons.tickets,
      title: 'قائمة الشكاوى',
      subtitle: showing == 0
          ? 'لا نتائج'
          : 'عرض ${TicketsFormat.count(first)}–${TicketsFormat.count(last)} '
                'من ${TicketsFormat.count(total)}',
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({required this.state});

  final TicketsLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.isFiltered) {
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
}

/// Below the table's breakpoint the same rows render as cards, because nine
/// truncated columns answer none of the questions an agent opened the queue
/// with.
class _TicketCardList extends StatelessWidget {
  const _TicketCardList({
    required this.rows,
    required this.total,
    required this.page,
    required this.pages,
    required this.onPageChanged,
    required this.onOpen,
  });

  final List<SupportTicket> rows;
  final int total;
  final int page;
  final int pages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<SupportTicket> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final ticket in rows) ...[
          _TicketCard(ticket: ticket, onOpen: onOpen),
          const SizedBox(height: AppSpacing.small),
        ],
        // The same bar the table closes with, so both layouts page identically.
        AppCard(
          padding: EdgeInsets.zero,
          child: DashboardPagerBar(
            totalLabel: 'الإجمالي ${TicketsFormat.count(total)} تذكرة',
            currentPage: page,
            pages: pages,
            onPageChanged: onPageChanged,
          ),
        ),
      ],
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onOpen});

  final SupportTicket ticket;
  final ValueChanged<SupportTicket> onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        onTap: () => onOpen(ticket),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${ticket.ticketNumber} · ${ticket.clientName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: DashboardColors.mutedInk(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                TicketSlaBadge(ticket: ticket),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.xSmall,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusBadge(status: ticket.status),
                PriorityBadge(priority: ticket.priority),
                _Fact(label: 'الفئة', value: ticket.category),
                _Fact(
                  label: 'المسؤول',
                  value: ticket.assignedAgentName ?? 'غير مسندة',
                ),
                _Fact(
                  label: 'تاريخ الإنشاء',
                  value: TicketsFormat.date(ticket.createdAt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: DashboardColors.mutedInk(context),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
