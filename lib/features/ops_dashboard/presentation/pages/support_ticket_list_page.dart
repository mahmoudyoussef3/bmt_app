import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/support_ticket.dart';
import '../cubit/support_ticket_cubit.dart';
import '../cubit/support_ticket_state.dart';

class SupportTicketListPage extends StatefulWidget {
  const SupportTicketListPage({super.key});

  @override
  State<SupportTicketListPage> createState() => _SupportTicketListPageState();
}

class _SupportTicketListPageState extends State<SupportTicketListPage> {
  TicketStatus? _filterStatus;
  String _search = '';
  final _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    context.read<SupportTicketCubit>().loadTicketsFiltered();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Tickets')),
      body: BlocBuilder<SupportTicketCubit, SupportTicketState>(
        builder: (context, state) {
          if (state is SupportTicketLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is SupportTicketError)
            return Center(child: Text('Error: ${state.message}'));
          final tickets = (state as SupportTicketLoaded).tickets;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(child: _buildSearch()),
                    const SizedBox(width: 8),
                    _buildStatusFilters(),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) => _buildRow(tickets[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Search by id/customer/subject',
      ),
      onChanged: (v) {
        _search = v;
        _debouncedSearch();
      },
    );
  }

  void _debouncedSearch() {
    // simple debounce
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchController.text == _search)
        context.read<SupportTicketCubit>().loadTicketsFiltered(
          status: _filterStatus,
          search: _search,
        );
    });
  }

  Widget _buildStatusFilters() {
    return Wrap(
      spacing: 6,
      children: TicketStatus.values.map((s) {
        final selected = s == _filterStatus;
        return ChoiceChip(
          label: Text(_statusLabel(s)),
          selected: selected,
          onSelected: (sel) {
            setState(() {
              _filterStatus = sel ? s : null;
            });
            context.read<SupportTicketCubit>().loadTicketsFiltered(
              status: _filterStatus,
              search: _search,
            );
          },
          backgroundColor: _statusColor(s).withOpacity(0.15),
          selectedColor: _statusColor(s),
          labelStyle: TextStyle(
            color: selected ? Colors.white : _statusColor(s),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRow(SupportTicket t) {
    return ListTile(
      title: Text(t.subject),
      subtitle: Text(
        'Customer: ${t.customerId} • ${t.priority.name} • ${t.createdAt.toLocal()}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(t.status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _statusLabel(t.status),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          _priorityBadge(t.priority),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SupportTicketDetailPage(ticketId: t.id),
        ),
      ),
    );
  }

  Widget _priorityBadge(TicketPriority p) {
    Color c;
    switch (p) {
      case TicketPriority.low:
        c = Colors.grey;
        break;
      case TicketPriority.medium:
        c = Colors.blue;
        break;
      case TicketPriority.high:
        c = Colors.orange;
        break;
      case TicketPriority.critical:
        c = Colors.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        p.name.toUpperCase(),
        style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  String _statusLabel(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.escalated:
        return 'Escalated';
      case TicketStatus.closed:
        return 'Closed';
    }
  }

  Color _statusColor(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:
        return Colors.green;
      case TicketStatus.inProgress:
        return Colors.blue;
      case TicketStatus.resolved:
        return Colors.grey;
      case TicketStatus.escalated:
        return Colors.red;
      case TicketStatus.closed:
        return Colors.black54;
    }
  }
}

class SupportTicketDetailPage extends StatefulWidget {
  final String ticketId;
  const SupportTicketDetailPage({required this.ticketId, super.key});

  @override
  State<SupportTicketDetailPage> createState() =>
      _SupportTicketDetailPageState();
}

class _SupportTicketDetailPageState extends State<SupportTicketDetailPage> {
  String? _selectedAgent;
  final _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SupportTicketCubit>();
    final state = cubit.state;
    SupportTicket? ticket;
    if (state is SupportTicketLoaded) {
      ticket = state.tickets.firstWhere(
        (t) => t.id == widget.ticketId,
        orElse: () => null,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ticket == null
            ? const Center(child: Text('Ticket not loaded'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(ticket.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _statusLabel(ticket.status),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Priority: ${ticket.priority.name.toUpperCase()}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Ticket ID: ${ticket.id}'),
                  const SizedBox(height: 4),
                  Text('Customer: ${ticket.customerId}'),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(ticket.description),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildAgentDropdown(ticket)),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (_selectedAgent != null) {
                            await cubit.assignAgent(ticket.id, _selectedAgent!);
                            setState(() {});
                          }
                        },
                        child: const Text('Assign'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _buildStatusActions(ticket, cubit),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Internal Notes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: ticket.internalNotes.length,
                      itemBuilder: (context, i) {
                        final n = ticket!.internalNotes[i];
                        return ListTile(
                          title: Text(n.note),
                          subtitle: Text(
                            'By ${n.agentId} • ${n.createdAt.toLocal()}',
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            hintText: 'Add internal note',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final text = _noteController.text.trim();
                          if (text.isNotEmpty) {
                            await cubit.addNote(
                              ticket!.id,
                              _selectedAgent ?? 'AGENT-UNASSIGNED',
                              text,
                            );
                            _noteController.clear();
                            setState(() {});
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAgentDropdown(SupportTicket ticket) {
    // Mock agents list
    final agents = ['AGENT-1', 'AGENT-2', 'AGENT-3'];
    _selectedAgent = ticket.assignedAgentId ?? _selectedAgent;
    return DropdownButton<String>(
      value: _selectedAgent,
      hint: const Text('Assign agent'),
      isExpanded: true,
      items: agents
          .map((a) => DropdownMenuItem(value: a, child: Text(a)))
          .toList(),
      onChanged: (v) => setState(() => _selectedAgent = v),
    );
  }

  List<Widget> _buildStatusActions(
    SupportTicket ticket,
    SupportTicketCubit cubit,
  ) {
    // allowed transitions: Open -> In Progress -> Resolved -> Escalated
    final actions = <Widget>[];
    if (ticket.status == TicketStatus.open) {
      actions.add(
        ElevatedButton(
          onPressed: () =>
              cubit.changeStatus(ticket.id, TicketStatus.inProgress),
          child: const Text('Start'),
        ),
      );
      actions.add(
        TextButton(
          onPressed: () =>
              cubit.changeStatus(ticket.id, TicketStatus.escalated),
          child: const Text('Escalate'),
        ),
      );
    } else if (ticket.status == TicketStatus.inProgress) {
      actions.add(
        ElevatedButton(
          onPressed: () => cubit.changeStatus(ticket.id, TicketStatus.resolved),
          child: const Text('Resolve'),
        ),
      );
      actions.add(
        TextButton(
          onPressed: () =>
              cubit.changeStatus(ticket.id, TicketStatus.escalated),
          child: const Text('Escalate'),
        ),
      );
    } else if (ticket.status == TicketStatus.resolved) {
      actions.add(
        TextButton(
          onPressed: () => cubit.changeStatus(ticket.id, TicketStatus.closed),
          child: const Text('Close'),
        ),
      );
    } else if (ticket.status == TicketStatus.escalated) {
      actions.add(
        ElevatedButton(
          onPressed: () =>
              cubit.changeStatus(ticket.id, TicketStatus.inProgress),
          child: const Text('Take Ownership'),
        ),
      );
    }
    return actions;
  }

  String _statusLabel(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.escalated:
        return 'Escalated';
      case TicketStatus.closed:
        return 'Closed';
    }
  }

  Color _statusColor(TicketStatus s) {
    switch (s) {
      case TicketStatus.open:
        return Colors.green;
      case TicketStatus.inProgress:
        return Colors.blue;
      case TicketStatus.resolved:
        return Colors.grey;
      case TicketStatus.escalated:
        return Colors.red;
      case TicketStatus.closed:
        return Colors.black54;
    }
  }
}
