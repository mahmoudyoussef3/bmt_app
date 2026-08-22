import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';

import '../../domain/entities/complaint.dart';
import '../cubit/tickets_cubit.dart';
import '../cubit/tickets_state.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

class _Template {
  const _Template(this.title, this.body);
  final String title;
  final String body;
}

const _kTemplates = [
  _Template('تم التواصل', 'تم التواصل مع العميل وجاري المتابعة.'),
  _Template('قيد الفحص', 'تم استلام البلاغ وهو قيد الفحص من الفريق المختص.'),
  _Template(
    'تم الحل',
    'تم حل المشكلة بنجاح. يرجى التواصل إذا احتجت لأي مساعدة إضافية.',
  ),
  _Template('تأخر رحلة', 'تأخر الرحلة ناتج عن ظروف تشغيلية. نعتذر عن الإزعاج.'),
  _Template('معلومات ناقصة', 'نحتاج معلومات إضافية لإتمام المعالجة.'),
];

class TicketDetailsDialog extends StatefulWidget {
  const TicketDetailsDialog({super.key});

  @override
  State<TicketDetailsDialog> createState() => _TicketDetailsDialogState();
}

class _TicketDetailsDialogState extends State<TicketDetailsDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketsCubit, TicketsState>(
      builder: (context, state) {
        if (state is! TicketsLoaded || state.selectedTicket == null) {
          return const AlertDialog(content: Text('لم يتم اختيار تذكرة'));
        }

        final ticket = state.selectedTicket!;
        final cubit = context.read<TicketsCubit>();

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.medium,
          ),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
            child: Column(
              children: [
                _TicketDialogHeader(ticket: ticket),
                const Divider(height: 1),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 780;
                      final details = _TicketDetailsPane(
                        ticket: ticket,
                        attachments: state.selectedTicketAttachments,
                      );
                      final actions = _TicketActionPane(
                        ticket: ticket,
                        state: state,
                        cubit: cubit,
                        noteController: _noteController,
                      );

                      if (isNarrow) {
                        return ListView(
                          padding: const EdgeInsets.all(AppSpacing.large),
                          children: [
                            details,
                            const SizedBox(height: AppSpacing.large),
                            actions,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 6,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(AppSpacing.large),
                              child: details,
                            ),
                          ),
                          VerticalDivider(
                            width: 1,
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(AppSpacing.large),
                              child: actions,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TicketDialogHeader extends StatelessWidget {
  const _TicketDialogHeader({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        AppSpacing.medium,
        AppSpacing.large,
        AppSpacing.medium,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _statusColor(context, ticket.status).withAlpha(24),
              borderRadius: BorderRadius.circular(AppTokens.radius),
            ),
            child: Icon(
              Icons.confirmation_number_outlined,
              color: _statusColor(context, ticket.status),
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تذكرة ${ticket.ticketNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          _TicketStatusBadge(status: ticket.status),
          const SizedBox(width: AppSpacing.small),
          _TicketPriorityBadge(priority: ticket.priority),
          const SizedBox(width: AppSpacing.small),
          IconButton(
            tooltip: 'إغلاق',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _TicketDetailsPane extends StatelessWidget {
  const _TicketDetailsPane({required this.ticket, required this.attachments});

  final SupportTicket ticket;
  final List<SupportAttachment>? attachments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.person_search_rounded,
          title: 'ملخص البلاغ',
          subtitle: 'بيانات العميل وسياق التذكرة',
        ),
        const SizedBox(height: AppSpacing.medium),
        _InfoGrid(
          items: [
            _InfoItem('الحالة', _statusLabel(ticket.status)),
            _InfoItem('الأولوية', _priorityLabel(ticket.priority)),
            _InfoItem('الفئة', _categoryLabel(ticket.category)),
            _InfoItem('العميل', ticket.clientName),
            _InfoItem('الهاتف', ticket.clientPhone),
            _InfoItem('تاريخ الإنشاء', _formatDateTime(ticket.createdAt)),
            if (ticket.customerContactedAt != null)
              _InfoItem(
                'آخر تواصل',
                _formatDateTime(ticket.customerContactedAt!),
              ),
            if (ticket.slaDueAt != null)
              _InfoItem('SLA', _formatDateTime(ticket.slaDueAt!)),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        _ContentBlock(
          title: 'العنوان',
          icon: Icons.subject_rounded,
          child: Text(ticket.title),
        ),
        const SizedBox(height: AppSpacing.medium),
        _ContentBlock(
          title: 'الوصف',
          icon: Icons.notes_rounded,
          child: Text(ticket.description),
        ),
        const SizedBox(height: AppSpacing.large),
        _AttachmentsBlock(attachments: attachments),
      ],
    );
  }
}

class _TicketActionPane extends StatelessWidget {
  const _TicketActionPane({
    required this.ticket,
    required this.state,
    required this.cubit,
    required this.noteController,
  });

  final SupportTicket ticket;
  final TicketsLoaded state;
  final TicketsCubit cubit;
  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.task_alt_rounded,
          title: 'إجراءات المعالجة',
          subtitle: 'حدّث الحالة وسجل خطوات المتابعة',
        ),
        const SizedBox(height: AppSpacing.medium),
        if (state.actionLoading) const LinearProgressIndicator(minHeight: 3),
        if (state.actionLoading) const SizedBox(height: AppSpacing.medium),
        _ActionGrid(ticket: ticket, cubit: cubit),
        const SizedBox(height: AppSpacing.large),
        _AssigneeCard(ticket: ticket, state: state, cubit: cubit),
        const SizedBox(height: AppSpacing.large),
        _ContentBlock(
          title: 'ملاحظة داخلية',
          icon: Icons.edit_note_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ticket.internalNote != null &&
                  ticket.internalNote!.trim().isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: context
                        .status(AppStatusTone.warning)
                        .tint
                        .withAlpha(170),
                    borderRadius: BorderRadius.circular(AppTokens.radius),
                    border: Border.all(
                      color: context
                          .status(AppStatusTone.warning)
                          .ink
                          .withAlpha(90),
                    ),
                  ),
                  child: Text(ticket.internalNote!),
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
              Text(
                'قوالب سريعة',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: _kTemplates.map((template) {
                  return ActionChip(
                    label: Text(template.title),
                    onPressed: () {
                      noteController.text = template.body;
                      noteController.selection = TextSelection.collapsed(
                        offset: template.body.length,
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.medium),
              TextField(
                controller: noteController,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'اكتب ملخص المتابعة أو القرار الداخلي...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              FilledButton.icon(
                onPressed: state.actionLoading
                    ? null
                    : () {
                        final note = noteController.text.trim();
                        if (note.isEmpty) return;
                        cubit.saveInternalNote(note);
                        noteController.clear();
                      },
                icon: const Icon(Icons.save_rounded),
                label: const Text('حفظ الملاحظة'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.ticket, required this.cubit});

  final SupportTicket ticket;
  final TicketsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];
    if (ticket.status == TicketStatus.submitted) {
      actions.add(
        FilledButton.icon(
          onPressed: () => cubit.updateStatus(TicketStatus.underReview),
          icon: const Icon(Icons.rate_review_rounded),
          label: const Text('بدء المراجعة'),
        ),
      );
    }
    if (ticket.status != TicketStatus.contacted &&
        ticket.status != TicketStatus.resolved &&
        ticket.status != TicketStatus.closed) {
      actions.add(
        FilledButton.tonalIcon(
          onPressed: cubit.markCustomerContacted,
          icon: const Icon(Icons.phone_in_talk_rounded),
          label: const Text('تم التواصل'),
        ),
      );
    }
    if (ticket.status != TicketStatus.resolved &&
        ticket.status != TicketStatus.closed) {
      actions.add(
        FilledButton.tonalIcon(
          onPressed: () => cubit.updateStatus(TicketStatus.resolved),
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('تم الحل'),
        ),
      );
    }
    if (ticket.status != TicketStatus.closed) {
      actions.add(
        OutlinedButton.icon(
          onPressed: cubit.closeTicket,
          icon: const Icon(Icons.lock_outline_rounded),
          label: const Text('إغلاق'),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: actions
          .map((action) => SizedBox(width: 160, child: action))
          .toList(),
    );
  }
}

class _AssigneeCard extends StatelessWidget {
  const _AssigneeCard({
    required this.ticket,
    required this.state,
    required this.cubit,
  });

  final SupportTicket ticket;
  final TicketsLoaded state;
  final TicketsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _ContentBlock(
      title: 'المسؤول عن التذكرة',
      icon: Icons.assignment_ind_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withAlpha(80),
              borderRadius: BorderRadius.circular(AppTokens.radius),
            ),
            child: Row(
              children: [
                Icon(Icons.support_agent_rounded, color: scheme.primary),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    ticket.assignedAgentName?.trim().isNotEmpty == true
                        ? ticket.assignedAgentName!
                        : 'لم يتم التعيين بعد',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          if (state.agents.isEmpty)
            Text(
              'لا يوجد مسؤولون متاحون حالياً',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            )
          else
            DropdownButtonFormField<String>(
              key: ValueKey(ticket.assignedAgentId),
              initialValue: ticket.assignedAgentId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'إسناد إلى',
                border: OutlineInputBorder(),
              ),
              items: state.agents.map((agent) {
                final id = agent['user_id'] as String? ?? '';
                final role = agent['role'] as String? ?? '';
                final name = agent['name'] as String? ?? id.substring(0, 8);
                return DropdownMenuItem(
                  value: id,
                  child: Text('$name - $role'),
                );
              }).toList(),
              onChanged: state.actionLoading
                  ? null
                  : (agentId) {
                      if (agentId == null) return;
                      final agent = state.agents.firstWhere(
                        (a) => a['user_id'] == agentId,
                        orElse: () => {},
                      );
                      final name =
                          agent['name'] as String? ?? agentId.substring(0, 8);
                      cubit.assignAgent(agentId, name);
                    },
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(AppTokens.radius),
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 560
            ? constraints.maxWidth
            : (constraints.maxWidth - AppSpacing.small) / 2;
        return Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _InfoTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value);
  final String label;
  final String value;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(62),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outlineVariant.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ContentBlock extends StatelessWidget {
  const _ContentBlock({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: AppSpacing.small),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          child,
        ],
      ),
    );
  }
}

class _AttachmentsBlock extends StatelessWidget {
  const _AttachmentsBlock({required this.attachments});

  final List<SupportAttachment>? attachments;

  @override
  Widget build(BuildContext context) {
    final files = attachments ?? const <SupportAttachment>[];
    return _ContentBlock(
      title: 'المرفقات',
      icon: Icons.attach_file_rounded,
      child: files.isEmpty
          ? Text(
              'لا توجد مرفقات لهذه التذكرة',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: [
                for (final file in files)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(
                      file.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'فتح المرفق',
                      icon: const Icon(Icons.open_in_new_rounded),
                      onPressed: () => launchUrl(Uri.parse(file.fileUrl)),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TicketStatusBadge extends StatelessWidget {
  const _TicketStatusBadge({required this.status});
  final TicketStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return DashboardStatusChip(
      label: _statusLabel(status),
      color: color.withAlpha(24),
      textColor: color,
    );
  }
}

class _TicketPriorityBadge extends StatelessWidget {
  const _TicketPriorityBadge({required this.priority});
  final TicketPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(context, priority);
    return DashboardStatusChip(
      label: _priorityLabel(priority),
      color: color.withAlpha(24),
      textColor: color,
    );
  }
}

String _statusLabel(TicketStatus status) {
  return switch (status) {
    TicketStatus.submitted => 'جديدة',
    TicketStatus.underReview => 'قيد المراجعة',
    TicketStatus.contacted => 'تم التواصل',
    TicketStatus.resolved => 'تم الحل',
    TicketStatus.closed => 'مغلقة',
    TicketStatus.rejected => 'مرفوضة',
  };
}

String _priorityLabel(TicketPriority priority) {
  return switch (priority) {
    TicketPriority.low => 'منخفضة',
    TicketPriority.medium => 'متوسطة',
    TicketPriority.high => 'مرتفعة',
    TicketPriority.urgent => 'عاجلة',
  };
}

String _categoryLabel(String category) {
  return switch (category.toLowerCase()) {
    'payment issue' || 'payment' => 'مشكلة دفع',
    'trip delay' || 'delay' => 'تأخر رحلة',
    'booking' || 'booking issue' => 'مشكلة حجز',
    'refund' => 'استرداد',
    _ => category,
  };
}

Color _statusColor(BuildContext context, TicketStatus status) {
  return switch (status) {
    TicketStatus.submitted => context.status(AppStatusTone.info).ink,
    TicketStatus.underReview => context.status(AppStatusTone.warning).ink,
    TicketStatus.contacted => context.status(AppStatusTone.special).ink,
    TicketStatus.resolved => context.status(AppStatusTone.success).ink,
    TicketStatus.closed => context.status(AppStatusTone.neutral).ink,
    TicketStatus.rejected => context.status(AppStatusTone.error).ink,
  };
}

Color _priorityColor(BuildContext context, TicketPriority priority) {
  return switch (priority) {
    TicketPriority.low => context.status(AppStatusTone.neutral).ink,
    TicketPriority.medium => context.status(AppStatusTone.info).ink,
    TicketPriority.high => context.status(AppStatusTone.warning).ink,
    TicketPriority.urgent => context.status(AppStatusTone.error).ink,
  };
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date  $time';
}
