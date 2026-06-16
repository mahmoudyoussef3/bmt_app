import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/complaint.dart';
import '../cubit/tickets_cubit.dart';
import '../cubit/tickets_state.dart';
import 'tickets_shared_widgets.dart';
import 'ticket_details_dialog.dart';

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
                  'Tickets (${filtered.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Filtered Tickets',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (filtered.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No tickets found.'),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Ticket Number', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Created At', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('SLA', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Agent', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filtered.map((t) {
                      return DataRow(
                        color: t.slaBreached
                            ? WidgetStateProperty.all(Colors.red.withAlpha(20))
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
                          DataCell(Text(t.ticketNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(t.clientName)),
                          DataCell(Text(t.category)),
                          DataCell(Text(t.title)),
                          DataCell(Text(
                            '${t.createdAt.year}/${t.createdAt.month}/${t.createdAt.day}',
                          )),
                          DataCell(StatusBadge(status: t.status)),
                          DataCell(PriorityBadge(priority: t.priority)),
                          DataCell(_SlaBadge(ticket: t)),
                          DataCell(Text(t.assignedAgentName ?? '—', style: const TextStyle(fontSize: 12))),
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

class _SlaBadge extends StatelessWidget {
  const _SlaBadge({required this.ticket});
  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    if (ticket.slaDueAt == null) return const Text('—', style: TextStyle(fontSize: 12));
    if (ticket.slaBreached) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(30),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.withAlpha(120)),
        ),
        child: const Text('BREACHED', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
      );
    }
    final remaining = ticket.slaDueAt!.difference(DateTime.now());
    final label = remaining.isNegative
        ? 'Overdue'
        : remaining.inHours > 0
            ? '${remaining.inHours}h left'
            : '${remaining.inMinutes}m left';
    final color = ticket.isSlaNearBreach ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
