import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/complaint.dart';
import '../cubit/tickets_cubit.dart';
import 'tickets_shared_widgets.dart';

class InfoTab extends StatelessWidget {
  final Complaint complaint;
  const InfoTab({super.key, required this.complaint});

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
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
          DetailField(label: 'رقم الرحلة التابع لها الشكوى', value: complaint.tripCode),
          DetailField(label: 'اسم العميل المسجل', value: complaint.clientName),
          DetailField(label: 'هاتف العميل', value: complaint.clientPhone),
          DetailField(
            label: 'تاريخ وتوقيت البلاغ',
            value: '${complaint.createdAt.year}/${complaint.createdAt.month}/${complaint.createdAt.day} ${complaint.createdAt.hour}:${complaint.createdAt.minute.toString().padLeft(2, '0')}',
          ),
          DetailField(label: 'نوع الشكوى / التصنيف', value: complaint.category.label),
          DetailField(label: 'المسؤول الحالي عن المعالجة', value: complaint.assignedTo ?? 'لم يتم التعيين لمسؤول بعد'),

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
                  backgroundColor: scheme.secondaryContainer.withValues(alpha: 0.4),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class ConversationTab extends StatefulWidget {
  final Complaint complaint;
  const ConversationTab({super.key, required this.complaint});

  @override
  State<ConversationTab> createState() => _ConversationTabState();
}

class _ConversationTabState extends State<ConversationTab> {
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
                        backgroundColor: scheme.primary.withValues(alpha: 0.12),
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
                              ? scheme.primaryContainer.withValues(alpha: 0.35)
                              : scheme.surfaceContainerHighest.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isAgent ? const Radius.circular(0) : const Radius.circular(16),
                            bottomRight: isAgent ? const Radius.circular(16) : const Radius.circular(0),
                          ),
                          border: Border.all(
                            color: isAgent
                                ? scheme.primary.withValues(alpha: 0.2)
                                : scheme.outline.withValues(alpha: 0.2),
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
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
            border: Border(top: BorderSide(color: scheme.outline.withValues(alpha: 0.2))),
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

class ActionsTab extends StatelessWidget {
  final Complaint complaint;
  const ActionsTab({super.key, required this.complaint});

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
                
              const Spacer(),

              // Delete Ticket Button
              OutlinedButton.icon(
                onPressed: () => _showDeleteConfirmation(context, cubit),
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                label: const Text('حذف الشكوى', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TicketsCubit cubit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف الشكوى'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذه الشكوى نهائياً؟ سيتم حذف جميع الرسائل والسجلات المرتبطة بها ولا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              cubit.deleteComplaint();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
  }
}

class HistoryTab extends StatelessWidget {
  final Complaint complaint;
  const HistoryTab({super.key, required this.complaint});

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
                  backgroundColor: scheme.primary.withValues(alpha: 0.25),
                  child: Icon(Icons.circle, size: 8, color: scheme.primary),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: scheme.outline.withValues(alpha: 0.3),
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
