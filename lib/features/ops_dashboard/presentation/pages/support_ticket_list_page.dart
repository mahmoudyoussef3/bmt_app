import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import '../../domain/models/support_ticket.dart';
import '../widgets/app_card.dart';
import '../widgets/status_chip.dart';
import '../cubit/support_ticket_cubit.dart';
import '../cubit/support_ticket_state.dart';

// Helpers
String _statusLabelFor(TicketStatus s) {
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

Color _statusColorFor(TicketStatus s) {
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

Color _priorityColorFor(TicketPriority p) {
  switch (p) {
    case TicketPriority.low:
      return Colors.grey;
    case TicketPriority.medium:
      return Colors.blue;
    case TicketPriority.high:
      return Colors.orange;
    case TicketPriority.critical:
      return Colors.red;
  }
}

class SupportTicketListPage extends StatefulWidget {
  const SupportTicketListPage({super.key});

  @override
  State<SupportTicketListPage> createState() => _SupportTicketListPageState();
}

class _SupportTicketListPageState extends State<SupportTicketListPage> {
  TicketStatus? _filterStatus;
  String _search = '';
  final _searchController = TextEditingController();
  String? _selectedTicketId;

  @override
  void initState() {
    super.initState();
    context.read<SupportTicketCubit>().loadTicketsFiltered();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _filterStatus != null || _search.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<SupportTicketCubit>().loadTicketsFiltered(
                status: _filterStatus,
                search: _search,
              );
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          if (hasActiveFilters)
            IconButton(
              onPressed: _resetFilters,
              icon: const Icon(Icons.filter_alt_off_rounded),
              tooltip: 'Clear filters',
            ),
        ],
      ),
      body: BlocBuilder<SupportTicketCubit, SupportTicketState>(
        builder: (context, state) {
          if (state is SupportTicketLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SupportTicketError) {
            return _buildErrorState(state.message);
          }
          final tickets = (state as SupportTicketLoaded).tickets;
          final openCount = tickets
              .where((t) => t.status == TicketStatus.open)
              .length;
          final inProgressCount = tickets
              .where((t) => t.status == TicketStatus.inProgress)
              .length;
          final escalatedCount = tickets
              .where((t) => t.status == TicketStatus.escalated)
              .length;

          return LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              if (w >= 900) {
                // master-detail two-pane
                final leftWidth = math
                    .max(320, math.min(520, (w * 0.36)))
                    .toDouble();
                return Row(
                  children: [
                    SizedBox(
                      width: leftWidth,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            _buildPageSummary(
                              total: tickets.length,
                              open: openCount,
                              inProgress: inProgressCount,
                              escalated: escalatedCount,
                            ),
                            const SizedBox(height: AppSpacing.small),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _buildFilterControls(isNarrow: false),
                            ),
                            Expanded(
                              child: tickets.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.separated(
                                      itemCount: tickets.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, i) =>
                                          _buildRow(tickets[i]),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _selectedTicketId == null
                          ? const Center(child: Text('Select a ticket'))
                          : _SupportTicketDetailPanel(
                              ticketId: _selectedTicketId!,
                            ),
                    ),
                  ],
                );
              }

              // narrow single-column
              return Column(
                children: [
                  _buildPageSummary(
                    total: tickets.length,
                    open: openCount,
                    inProgress: inProgressCount,
                    escalated: escalatedCount,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildFilterControls(isNarrow: true),
                  ),
                  Expanded(
                    child: tickets.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            itemCount: tickets.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) => _buildRow(tickets[i]),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search by id, customer, or subject',
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        suffixIcon: _search.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchController.clear();
                  _search = '';
                  context.read<SupportTicketCubit>().loadTicketsFiltered(
                    status: _filterStatus,
                    search: _search,
                  );
                  setState(() {});
                },
              ),
      ),
      onChanged: (v) {
        _search = v;
        setState(() {});
        _debouncedSearch();
      },
    );
  }

  Widget _buildFilterControls({required bool isNarrow}) {
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearch(),
          const SizedBox(height: AppSpacing.small),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildStatusFilters(),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildSearch()),
        const SizedBox(width: AppSpacing.small),
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildStatusFilters(),
          ),
        ),
      ],
    );
  }

  Widget _buildPageSummary({
    required int total,
    required int open,
    required int inProgress,
    required int escalated,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ticket Operations',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            'Track incoming load, active work, and urgent escalations.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              _summaryPill('Total', total.toString(), Colors.blueGrey),
              _summaryPill('Open', open.toString(), Colors.green),
              _summaryPill('In Progress', inProgress.toString(), Colors.blue),
              _summaryPill('Escalated', escalated.toString(), Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _debouncedSearch() {
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
          label: Text(_statusLabelFor(s)),
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
          backgroundColor: _statusColorFor(s).withOpacity(0.15),
          selectedColor: _statusColorFor(s),
          labelStyle: TextStyle(
            color: selected ? Colors.white : _statusColorFor(s),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRow(SupportTicket t) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = _selectedTicketId == t.id;
    final createdAtText = _formatTicketDate(t.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Material(
        color: isSelected
            ? scheme.primaryContainer.withOpacity(0.34)
            : scheme.surface,
        elevation: AppTokens.surfaceElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          side: BorderSide(
            color: isSelected
                ? scheme.primary.withOpacity(0.6)
                : scheme.outline.withOpacity(0.12),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          onTap: () {
            final w = MediaQuery.of(context).size.width;
            if (w >= 900) {
              setState(() => _selectedTicketId = t.id);
            } else {
              final cubit = context.read<SupportTicketCubit>();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: SupportTicketDetailPage(ticketId: t.id),
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: AppSpacing.card,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColorFor(t.status),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    t.customerId.length >= 2
                        ? t.customerId.substring(0, 2)
                        : t.customerId,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xSmall),
                      Text(
                        'Customer: ${t.customerId} • $createdAtText',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusChip(
                        label: _statusLabelFor(t.status),
                        color: _statusColorFor(t.status),
                      ),
                      const SizedBox(height: 6),
                      _priorityBadge(t.priority),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _priorityBadge(TicketPriority p) {
    final c = _priorityColorFor(p);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        p.name.toUpperCase(),
        style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 44,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.42),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              'No Tickets Found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xSmall),
            Text(
              'Try adjusting filters or search terms to find matching tickets.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
            const SizedBox(height: AppSpacing.small),
            Text(
              'Unable to load tickets',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xSmall),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.small),
            ElevatedButton.icon(
              onPressed: () {
                context.read<SupportTicketCubit>().loadTicketsFiltered(
                  status: _filterStatus,
                  search: _search,
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _filterStatus = null;
      _search = '';
      _searchController.clear();
    });
    context.read<SupportTicketCubit>().loadTicketsFiltered();
  }

  String _formatTicketDate(DateTime date) {
    final d = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _SupportTicketDetailPanel extends StatefulWidget {
  final String ticketId;
  const _SupportTicketDetailPanel({required this.ticketId});

  @override
  State<_SupportTicketDetailPanel> createState() =>
      _SupportTicketDetailPanelState();
}

class _SupportTicketDetailPanelState extends State<_SupportTicketDetailPanel> {
  String? _selectedAgent;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SupportTicketCubit>();
    final state = cubit.state;
    SupportTicket? ticket;
    if (state is SupportTicketLoaded) {
      ticket = state.tickets.firstWhere(
        (t) => t.id == widget.ticketId,
        orElse: () => SupportTicket(
          id: widget.ticketId,
          customerId: 'unknown',
          subject: 'Unknown',
          description: '',
        ),
      );
    }

    if (ticket == null) return const Center(child: Text('Ticket not loaded'));
    final t = ticket;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _TicketDetailContent(
        ticket: t,
        selectedAgent: _selectedAgent,
        onAgentChanged: (v) => setState(() => _selectedAgent = v),
        statusActions: _buildStatusActions(t, cubit),
        noteController: _noteController,
        onAssign: () async {
          if (_selectedAgent != null) {
            await cubit.assignAgent(t.id, _selectedAgent!);
            if (mounted) setState(() {});
          }
        },
        onAddNote: () async {
          final text = _noteController.text.trim();
          if (text.isNotEmpty) {
            await cubit.addNote(
              t.id,
              _selectedAgent ?? 'AGENT-UNASSIGNED',
              text,
            );
            _noteController.clear();
            if (mounted) setState(() {});
          }
        },
      ),
    );
  }

  List<Widget> _buildStatusActions(
    SupportTicket ticket,
    SupportTicketCubit cubit,
  ) {
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
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SupportTicketCubit>();
    final state = cubit.state;
    SupportTicket? ticket;
    if (state is SupportTicketLoaded) {
      ticket = state.tickets.firstWhere(
        (t) => t.id == widget.ticketId,
        orElse: () => SupportTicket(
          id: widget.ticketId,
          customerId: 'unknown',
          subject: 'Unknown',
          description: '',
        ),
      );
    }

    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ticket')),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Ticket not loaded')),
        ),
      );
    }

    final t = ticket;

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _TicketDetailContent(
          ticket: t,
          selectedAgent: _selectedAgent,
          onAgentChanged: (v) => setState(() => _selectedAgent = v),
          statusActions: _buildStatusActions(t, cubit),
          noteController: _noteController,
          onAssign: () async {
            if (_selectedAgent != null) {
              await cubit.assignAgent(t.id, _selectedAgent!);
              if (mounted) setState(() {});
            }
          },
          onAddNote: () async {
            final text = _noteController.text.trim();
            if (text.isNotEmpty) {
              await cubit.addNote(
                t.id,
                _selectedAgent ?? 'AGENT-UNASSIGNED',
                text,
              );
              _noteController.clear();
              if (mounted) setState(() {});
            }
          },
        ),
      ),
    );
  }

  List<Widget> _buildStatusActions(
    SupportTicket ticket,
    SupportTicketCubit cubit,
  ) {
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
}

class _TicketDetailContent extends StatelessWidget {
  final SupportTicket ticket;
  final String? selectedAgent;
  final ValueChanged<String?> onAgentChanged;
  final List<Widget> statusActions;
  final TextEditingController noteController;
  final Future<void> Function() onAssign;
  final Future<void> Function() onAddNote;

  const _TicketDetailContent({
    required this.ticket,
    required this.selectedAgent,
    required this.onAgentChanged,
    required this.statusActions,
    required this.noteController,
    required this.onAssign,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final agents = const ['AGENT-1', 'AGENT-2', 'AGENT-3'];
    final priorityColor = _priorityColorFor(ticket.priority);

    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.subject,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.small),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  StatusChip(
                    label: _statusLabelFor(ticket.status),
                    color: _statusColorFor(ticket.status),
                  ),
                  Container(
                    padding: AppSpacing.chip,
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(
                        AppTokens.radiusSmall,
                      ),
                    ),
                    child: Text(
                      'Priority: ${ticket.priority.name.toUpperCase()}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: priorityColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Ticket ID: ${ticket.id}  •  Customer: ${ticket.customerId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withOpacity(0.72),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Expanded(
          child: ListView(
            children: [
              AppCard(
                title: 'Description',
                child: Text(
                  ticket.description.isEmpty
                      ? 'No description provided.'
                      : ticket.description,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              AppCard(
                title: 'Workflow',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 520;
                        if (narrow) {
                          return Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: selectedAgent,
                                hint: const Text('Assign agent'),
                                isExpanded: true,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: scheme.surfaceContainerHighest
                                      .withOpacity(0.25),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTokens.radiusSmall,
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: agents
                                    .map(
                                      (a) => DropdownMenuItem(
                                        value: a,
                                        child: Text(a),
                                      ),
                                    )
                                    .toList(),
                                onChanged: onAgentChanged,
                              ),
                              const SizedBox(height: AppSpacing.small),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: onAssign,
                                  icon: const Icon(Icons.person_add_alt_1),
                                  label: const Text('Assign'),
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedAgent,
                                hint: const Text('Assign agent'),
                                isExpanded: true,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: scheme.surfaceContainerHighest
                                      .withOpacity(0.25),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTokens.radiusSmall,
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: agents
                                    .map(
                                      (a) => DropdownMenuItem(
                                        value: a,
                                        child: Text(a),
                                      ),
                                    )
                                    .toList(),
                                onChanged: onAgentChanged,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.small),
                            ElevatedButton.icon(
                              onPressed: onAssign,
                              icon: const Icon(Icons.person_add_alt_1),
                              label: const Text('Assign'),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.small,
                      children: statusActions,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              AppCard(
                title: 'Internal Notes',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ticket.internalNotes.isEmpty)
                      Text(
                        'No notes added yet.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(0.72),
                        ),
                      ),
                    ...ticket.internalNotes.map(
                      (n) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.small,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.small),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withOpacity(
                              0.2,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusSmall,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.note),
                              const SizedBox(height: AppSpacing.xSmall),
                              Text(
                                'By ${n.agentId} • ${n.createdAt.toLocal()}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurface.withOpacity(0.68),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: noteController,
                            decoration: InputDecoration(
                              hintText: 'Add internal note',
                              filled: true,
                              fillColor: scheme.surfaceContainerHighest
                                  .withOpacity(0.25),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTokens.radiusSmall,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        ElevatedButton.icon(
                          onPressed: onAddNote,
                          icon: const Icon(Icons.add_comment_outlined),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
