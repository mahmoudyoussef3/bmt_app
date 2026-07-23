import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/complaint.dart';
import '../cubit/tickets_cubit.dart';
import '../cubit/tickets_state.dart';
import 'tickets_shared_widgets.dart';
import 'ticket_details_dialog.dart';
import 'package:bmt_app/core/theme/tokens.dart';

class TicketsTable extends StatelessWidget {
  final TicketsLoaded state;
  const TicketsTable({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final filtered = state.filteredTickets;
    final cubit = context.read<TicketsCubit>();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'التذاكر (${filtered.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'النتائج المفلترة',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (filtered.isEmpty)
            const Expanded(child: Center(child: Text('لا توجد تذاكر.')))
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'رقم التذكرة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'العميل',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'الفئة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'العنوان',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'تاريخ الإنشاء',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'الحالة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'الأولوية',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'SLA',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'المسؤول',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: filtered.map((t) {
                      return DataRow(
                        color: t.slaBreached
                            ? WidgetStateProperty.all(
                                AppStatusColors.errorContainer,
                              )
                            : null,
                        onSelectChanged: (_) {
                          cubit.selectTicket(t.id);
                          showDialog(
                            context: context,
                            builder: (context) => BlocProvider.value(
                              value: cubit,
                              child: const TicketDetailsDialog(),
                            ),
                          );
                        },
                        cells: [
                          DataCell(
                            Text(
                              t.ticketNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(Text(t.clientName)),
                          DataCell(Text(t.category)),
                          DataCell(Text(t.title)),
                          DataCell(
                            Text(
                              '${t.createdAt.year}/${t.createdAt.month}/${t.createdAt.day}',
                            ),
                          ),
                          DataCell(StatusBadge(status: t.status)),
                          DataCell(PriorityBadge(priority: t.priority)),
                          DataCell(_SlaBadge(ticket: t)),
                          DataCell(
                            Text(
                              t.assignedAgentName ?? '—',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
      return const Text('—', style: TextStyle(fontSize: 12));
    }

    if (ticket.slaBreached) {
      return _badge(
        'BREACHED',
        AppStatusColors.errorContainer,
        AppStatusColors.onErrorContainer,
        bold: true,
      );
    }

    final remaining = ticket.slaDueAt!.difference(DateTime.now());
    if (remaining.isNegative) {
      return _badge(
        'Overdue',
        AppStatusColors.errorContainer,
        AppStatusColors.onErrorContainer,
        bold: true,
      );
    }

    final label = remaining.inHours > 0
        ? '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m left'
        : '${remaining.inMinutes}m left';
    final (bg, fg) = ticket.isSlaNearBreach
        ? (AppStatusColors.warningContainer, AppStatusColors.onWarningContainer)
        : (
            AppStatusColors.successContainer,
            AppStatusColors.onSuccessContainer,
          );
    return _badge(label, bg, fg);
  }

  Widget _badge(String label, Color bg, Color fg, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: fg,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
