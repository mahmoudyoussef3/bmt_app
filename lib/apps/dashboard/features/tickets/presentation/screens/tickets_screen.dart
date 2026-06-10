import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

import '../../domain/entities/complaint.dart';
import '../cubit/tickets_cubit.dart';
import '../cubit/tickets_state.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TicketsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مركز إدارة الشكاوى والمقترحات'),
          actions: [
            IconButton(
              tooltip: 'تحديث البيانات',
              onPressed: () => context.read<TicketsCubit>().load(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: BlocConsumer<TicketsCubit, TicketsState>(
          listenWhen: (previous, current) {
            return current is TicketsLoaded && current.actionMessage != null;
          },
          listener: (context, state) {
            if (state is TicketsLoaded && state.actionMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionMessage!),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<TicketsCubit>().clearActionMessage();
            }
          },
          builder: (context, state) {
            return switch (state) {
              TicketsLoading() => const Center(child: CircularProgressIndicator()),
              TicketsError(:final message) => _ErrorView(message: message),
              TicketsLoaded() => _LoadedView(state: state),
            };
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.read<TicketsCubit>().load(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final TicketsLoaded state;
  const _LoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedComplaint;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        children: [
          // 1. Stats Row
          _SummaryStats(state: state),
          const SizedBox(height: AppSpacing.medium),

          // 2. Filter Bar
          _FilterBar(state: state),
          const SizedBox(height: AppSpacing.medium),

          // 3. Workspace Layout
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useSplit = constraints.maxWidth > 950;

                if (!useSplit) {
                  // Single view layout: Show table if no selected, else detail
                  if (selected != null) {
                    return Column(
                      children: [
                        TextButton.icon(
                          onPressed: () => context.read<TicketsCubit>().selectComplaint(''),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('العودة لقائمة الشكاوى'),
                        ),
                        Expanded(child: _DetailWorkspace(complaint: selected, state: state)),
                      ],
                    );
                  }
                  return _ComplaintsTable(state: state);
                }

                // Split Layout: 40% Table / 60% Detail Workspace
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _ComplaintsTable(state: state),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      flex: 6,
                      child: selected == null
                          ? const AppCard(
                              child: EmptyState(
                                title: 'اختر شكوى من الجدول لعرض تفاصيلها',
                                subtitle: 'تظهر هنا المحادثات والملفات والإجراءات والسجل الخاص بالشكوى.',
                              ),
                            )
                          : _DetailWorkspace(complaint: selected, state: state),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStats extends StatelessWidget {
  final TicketsLoaded state;
  const _SummaryStats({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'شكاوى جديدة',
            value: state.newCount,
            color: Colors.blue,
            icon: Icons.mark_email_unread_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: _StatCard(
            title: 'قيد المعالجة',
            value: state.inProgressCount,
            color: Colors.orange,
            icon: Icons.pending_actions_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: _StatCard(
            title: 'تم الحل',
            value: state.resolvedCount,
            color: Colors.green,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: _StatCard(
            title: 'متأخرة (>24 ساعة)',
            value: state.delayedCount,
            color: Colors.red,
            icon: Icons.running_with_errors_outlined,
            isAlert: state.delayedCount > 0,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;
  final bool isAlert;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Container(
        decoration: isAlert
            ? BoxDecoration(
                border: Border.all(color: Colors.red.withOpacity(0.4), width: 1.5),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              radius: 24,
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: AppSpacing.medium),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isAlert ? Colors.red : scheme.onSurface,
                      ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TicketsLoaded state;
  const _FilterBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TicketsCubit>();

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.small),
        child: Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.small,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Search Input
            SizedBox(
              width: 260,
              child: TextField(
                onChanged: cubit.setSearchQuery,
                decoration: const InputDecoration(
                  hintText: 'البحث عن شكوى (الرقم، العميل، الرحلة)...',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),

            // Status Filter Dropdown
            _DropdownFilter<ComplaintStatus>(
              label: 'الحالة',
              value: state.filterStatus,
              items: ComplaintStatus.values,
              labelMapper: (v) => v.label,
              onChanged: cubit.setFilterStatus,
            ),

            // Priority Filter Dropdown
            _DropdownFilter<ComplaintPriority>(
              label: 'الأولوية',
              value: state.filterPriority,
              items: ComplaintPriority.values,
              labelMapper: (v) => v.label,
              onChanged: cubit.setFilterPriority,
            ),

            // Category Filter Dropdown
            _DropdownFilter<ComplaintCategory>(
              label: 'نوع الشكوى',
              value: state.filterCategory,
              items: ComplaintCategory.values,
              labelMapper: (v) => v.label,
              onChanged: cubit.setFilterCategory,
            ),

            // Reset Button
            if (state.filterStatus != null ||
                state.filterPriority != null ||
                state.filterCategory != null ||
                state.searchQuery.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  cubit.setFilterStatus(null);
                  cubit.setFilterPriority(null);
                  cubit.setFilterCategory(null);
                  cubit.setSearchQuery('');
                },
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: const Text('تهيئة الفلاتر'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DropdownFilter<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) labelMapper;
  final ValueChanged<T?> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.labelMapper,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        DropdownButton<T>(
          value: value,
          hint: Text('الكل', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text('الكل', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
            ...items.map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(labelMapper(item)),
              ),
            )
          ],
          onChanged: onChanged,
          underline: const SizedBox(),
        ),
      ],
    );
  }
}

class _ComplaintsTable extends StatelessWidget {
  final TicketsLoaded state;
  const _ComplaintsTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final filtered = state.filteredComplaints;
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
                  'قائمة الشكاوى (${filtered.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'الشكاوى المفلترة',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (filtered.isEmpty)
            const Expanded(
              child: Center(
                child: EmptyState(
                  title: 'لم يتم العثور على أي شكاوى مطابقة للفلاتر',
                  subtitle: 'يرجى تهيئة الفلاتر أو تغيير كلمة البحث.',
                ),
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
                      DataColumn(label: Text('رقم الشكوى', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('العميل', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('نوع الشكوى', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الرحلة', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('تاريخ الإنشاء', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('المسؤول', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الأولوية', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filtered.map((c) {
                      final isSelected = c.id == state.selectedComplaintId;
                      return DataRow(
                        selected: isSelected,
                        onSelectChanged: (_) => cubit.selectComplaint(c.id),
                        cells: [
                          DataCell(Text(c.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(c.clientName)),
                          DataCell(Text(c.category.label)),
                          DataCell(Text(c.tripCode)),
                          DataCell(Text(
                            '${c.createdAt.year}/${c.createdAt.month}/${c.createdAt.day}',
                          )),
                          DataCell(Text(c.assignedTo ?? 'غير معين', style: TextStyle(color: c.assignedTo == null ? Colors.red : null))),
                          DataCell(_StatusBadge(status: c.status)),
                          DataCell(_PriorityBadge(priority: c.priority)),
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

class _StatusBadge extends StatelessWidget {
  final ComplaintStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ComplaintStatus.newlyCreated => Colors.blue,
      ComplaintStatus.inProgress => Colors.orange,
      ComplaintStatus.waitingForClient => Colors.purple,
      ComplaintStatus.resolved => Colors.green,
      ComplaintStatus.closed => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final ComplaintPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      ComplaintPriority.low => Colors.grey,
      ComplaintPriority.medium => Colors.blue,
      ComplaintPriority.high => Colors.orange,
      ComplaintPriority.critical => Colors.red.shade900,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        priority.label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DetailWorkspace extends StatefulWidget {
  final Complaint complaint;
  final TicketsLoaded state;

  const _DetailWorkspace({
    required this.complaint,
    required this.state,
  });

  @override
  State<_DetailWorkspace> createState() => _DetailWorkspaceState();
}

class _DetailWorkspaceState extends State<_DetailWorkspace> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didUpdateWidget(covariant _DetailWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep tab selected when changing ticket
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'تفاصيل الشكوى: ${widget.complaint.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(status: widget.complaint.status),
                          const SizedBox(width: 8),
                          _PriorityBadge(priority: widget.complaint.priority),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'العميل: ${widget.complaint.clientName} · ${widget.complaint.clientPhone}',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (widget.state.actionLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.outline,
            tabs: const [
              Tab(text: 'معلومات'),
              Tab(text: 'المحادثة'),
              Tab(text: 'الإجراءات'),
              Tab(text: 'السجل'),
            ],
          ),

          // Tab Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _InfoTab(complaint: widget.complaint),
                _ConversationTab(complaint: widget.complaint),
                _ActionsTab(complaint: widget.complaint),
                _HistoryTab(complaint: widget.complaint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final Complaint complaint;
  const _InfoTab({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تفاصيل ووصف الشكوى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: Text(
              complaint.description,
              style: const TextStyle(height: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          const Text('تفاصيل الرحلة والعميل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          _DetailField(label: 'رقم الرحلة التابع لها الشكوى', value: complaint.tripCode),
          _DetailField(label: 'اسم العميل المسجل', value: complaint.clientName),
          _DetailField(label: 'هاتف العميل', value: complaint.clientPhone),
          _DetailField(
            label: 'تاريخ وتوقيت البلاغ',
            value: '${complaint.createdAt.year}/${complaint.createdAt.month}/${complaint.createdAt.day} ${complaint.createdAt.hour}:${complaint.createdAt.minute.toString().padLeft(2, '0')}',
          ),
          _DetailField(label: 'نوع الشكوى / التصنيف', value: complaint.category.label),
          _DetailField(label: 'المسؤول الحالي عن المعالجة', value: complaint.assignedTo ?? 'لم يتم التعيين لمسؤول بعد'),

          // Attachments Section
          if (complaint.attachments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.large),
            const Text('الملفات والمرفقات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: complaint.attachments.map((file) {
                return Chip(
                  avatar: const Icon(Icons.attach_file_rounded, size: 16),
                  label: Text(file, style: const TextStyle(fontSize: 12)),
                  backgroundColor: scheme.secondaryContainer.withOpacity(0.4),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;
  const _DetailField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              '$label: ',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTab extends StatefulWidget {
  final Complaint complaint;
  const _ConversationTab({required this.complaint});

  @override
  State<_ConversationTab> createState() => _ConversationTabState();
}

class _ConversationTabState extends State<_ConversationTab> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _selectedAttachments = [];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendResponse() {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedAttachments.isEmpty) return;

    context.read<TicketsCubit>().respond(
          text,
          attachments: List<String>.from(_selectedAttachments),
        );

    _messageController.clear();
    setState(() {
      _selectedAttachments.clear();
    });
  }

  void _toggleMockAttachment() {
    setState(() {
      if (_selectedAttachments.isEmpty) {
        _selectedAttachments.add('سجل_النظام_المرفق.log');
      } else {
        _selectedAttachments.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Message List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.medium),
            itemCount: widget.complaint.conversation.length,
            itemBuilder: (context, index) {
              final msg = widget.complaint.conversation[index];
              final isAgent = msg.senderType == 'agent';

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                child: Row(
                  mainAxisAlignment:
                      isAgent ? MainAxisAlignment.start : MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAgent) ...[
                      CircleAvatar(
                        backgroundColor: scheme.primary.withOpacity(0.12),
                        child: Text(
                          msg.senderName.substring(0, 1),
                          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAgent
                              ? scheme.primaryContainer.withOpacity(0.35)
                              : scheme.surfaceContainerHighest.withOpacity(0.8),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isAgent ? const Radius.circular(0) : const Radius.circular(16),
                            bottomRight: isAgent ? const Radius.circular(16) : const Radius.circular(0),
                          ),
                          border: Border.all(
                            color: isAgent
                                ? scheme.primary.withOpacity(0.2)
                                : scheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  msg.senderName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(msg.content, style: const TextStyle(fontSize: 13, height: 1.4)),

                            // Message attachments
                            if (msg.attachments.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                children: msg.attachments.map((file) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: scheme.surface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.attach_file, size: 12),
                                        const SizedBox(width: 4),
                                        Text(file, style: const TextStyle(fontSize: 10)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!isAgent) ...[
                      const SizedBox(width: AppSpacing.small),
                      CircleAvatar(
                        backgroundColor: scheme.secondaryContainer,
                        child: Text(
                          msg.senderName.substring(0, 1),
                          style: TextStyle(color: scheme.onSecondaryContainer, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),

        // Attachment draft chip
        if (_selectedAttachments.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: scheme.surfaceContainerHighest.withOpacity(0.5),
            child: Row(
              children: [
                const Icon(Icons.attach_file_rounded, size: 16),
                const SizedBox(width: 8),
                Text(_selectedAttachments.first, style: const TextStyle(fontSize: 12)),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _selectedAttachments.clear()),
                  icon: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ),

        // Message Composer
        Container(
          padding: const EdgeInsets.all(AppSpacing.small),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outline.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: _selectedAttachments.isEmpty ? 'إرفاق ملف' : 'إزالة المرفق',
                onPressed: _toggleMockAttachment,
                icon: Icon(
                  _selectedAttachments.isEmpty ? Icons.attach_file_rounded : Icons.attachment_rounded,
                  color: _selectedAttachments.isNotEmpty ? scheme.primary : null,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  onSubmitted: (_) => _sendResponse(),
                  decoration: const InputDecoration(
                    hintText: 'اكتب رداً لإرساله للعميل...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              IconButton(
                onPressed: _sendResponse,
                icon: const Icon(Icons.send_rounded),
                color: scheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionsTab extends StatelessWidget {
  final Complaint complaint;
  const _ActionsTab({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TicketsCubit>();
    final scheme = Theme.of(context).colorScheme;

    final supportAgents = ['عادل إمام', 'ريهام سعيد', 'هشام الجخ', 'ياسر جلال', 'مي فاروق'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تعديل حالة الشكوى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ComplaintStatus.values.map((status) {
              final isCurrent = complaint.status == status;
              return ChoiceChip(
                label: Text(status.label),
                selected: isCurrent,
                onSelected: (selected) {
                  if (selected && !isCurrent) {
                    cubit.updateStatus(status);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.large),
          const Text('تعيين مسؤول لمتابعة التذكرة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: supportAgents.map((agent) {
              final isAssigned = complaint.assignedTo == agent;
              return OutlinedButton.icon(
                onPressed: () => cubit.assign(agent),
                icon: Icon(isAssigned ? Icons.person_rounded : Icons.person_outline_rounded),
                label: Text(agent),
                style: isAssigned
                    ? OutlinedButton.styleFrom(
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                      )
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.large),
          const Text('إجراءات سريعة وتصعيد التذاكر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              // Escalate Button
              if (complaint.priority != ComplaintPriority.critical)
                FilledButton.icon(
                  onPressed: () => cubit.escalate(),
                  icon: const Icon(Icons.campaign_rounded),
                  label: const Text('تصعيد التذكرة (حرجة)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                const OutlinedButton(
                  onPressed: null,
                  child: Text('تم تصعيد التذكرة للدرجة القصوى'),
                ),
              const SizedBox(width: AppSpacing.small),

              // Close Ticket Button
              if (complaint.status != ComplaintStatus.closed)
                OutlinedButton.icon(
                  onPressed: () => cubit.closeComplaint(),
                  icon: const Icon(Icons.lock_rounded, color: Colors.grey),
                  label: const Text('إغلاق الشكوى نهائياً', style: TextStyle(color: Colors.grey)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final Complaint complaint;
  const _HistoryTab({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.medium),
      itemCount: complaint.history.length,
      itemBuilder: (context, index) {
        final log = complaint.history[index];
        final isLast = index == complaint.history.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: scheme.primary.withOpacity(0.25),
                  child: Icon(Icons.circle, size: 8, color: scheme.primary),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: scheme.outline.withOpacity(0.3),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.action,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${log.timestamp.year}/${log.timestamp.month}/${log.timestamp.day} ${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')} · بواسطة ${log.actor}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
