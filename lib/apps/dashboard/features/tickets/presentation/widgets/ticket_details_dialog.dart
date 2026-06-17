import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bmt_app/core/theme/colors.dart';

import '../../domain/entities/complaint.dart';
import '../cubit/tickets_cubit.dart';
import '../cubit/tickets_state.dart';
import 'tickets_shared_widgets.dart';

class _Template {
  const _Template(this.title, this.body);
  final String title;
  final String body;
}

const _kTemplates = [
  _Template('Contacted', 'تم التواصل مع العميل وجاري المتابعة.'),
  _Template('Under investigation', 'تم استلام البلاغ وهو قيد الفحص من الفريق المختص.'),
  _Template('Resolved', 'تم حل المشكلة بنجاح. يرجى التواصل إذا احتجت لأي مساعدة إضافية.'),
  _Template('Trip delay', 'تأخر الرحلة ناتج عن ظروف خارجة عن إرادتنا. نعتذر عن الإزعاج.'),
  _Template('Needs info', 'نحتاج معلومات إضافية لإتمام المعالجة. يرجى التواصل معنا.'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تذكرة ${ticket.ticketNumber}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
                const Divider(height: 32),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Details)
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DetailField(label: 'الحالة', value: ticket.status.label),
                              DetailField(label: 'الأولوية', value: ticket.priority.label),
                              DetailField(label: 'الفئة', value: ticket.category),
                              DetailField(label: 'العميل', value: '${ticket.clientName} (${ticket.clientPhone})'),
                              DetailField(label: 'تاريخ الإنشاء', value: '${ticket.createdAt.toLocal()}'),
                              if (ticket.customerContactedAt != null)
                                DetailField(label: 'تاريخ التواصل', value: '${ticket.customerContactedAt!.toLocal()}'),
                              const SizedBox(height: 16),
                              
                              const Text('العنوان', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(ticket.title),
                              const SizedBox(height: 16),

                              const Text('الوصف', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppStatusColors.neutralContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(ticket.description),
                              ),

                              if (state.selectedTicketAttachments != null && state.selectedTicketAttachments!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Text('المرفقات', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ...state.selectedTicketAttachments!.map(
                                  (a) => ListTile(
                                    leading: const Icon(Icons.attachment),
                                    title: Text(a.fileName),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.open_in_new),
                                      onPressed: () => launchUrl(Uri.parse(a.fileUrl)),
                                    ),
                                  )
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column (Actions & Notes)
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('الإجراءات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 12),
                              
                              if (ticket.status == TicketStatus.submitted)
                                FilledButton.icon(
                                  onPressed: () => cubit.updateStatus(TicketStatus.underReview),
                                  icon: const Icon(Icons.rate_review),
                                  label: const Text('قيد المراجعة'),
                                ),
                              
                              if (ticket.status != TicketStatus.contacted && ticket.status != TicketStatus.resolved && ticket.status != TicketStatus.closed)
                                ...[
                                  const SizedBox(height: 8),
                                  FilledButton.tonalIcon(
                                    onPressed: () => cubit.markCustomerContacted(),
                                    icon: const Icon(Icons.phone_in_talk),
                                    label: const Text('تم التواصل'),
                                  ),
                                ],

                              if (ticket.status != TicketStatus.resolved && ticket.status != TicketStatus.closed)
                                ...[
                                  const SizedBox(height: 8),
                                  FilledButton.tonalIcon(
                                    onPressed: () => cubit.updateStatus(TicketStatus.resolved),
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('تم الحل'),
                                    style: FilledButton.styleFrom(backgroundColor: AppStatusColors.successContainer, foregroundColor: AppStatusColors.onSuccessContainer),
                                  ),
                                ],

                              if (ticket.status != TicketStatus.closed)
                                ...[
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () => cubit.closeTicket(),
                                    icon: const Icon(Icons.close),
                                    label: const Text('إغلاق التذكرة'),
                                    style: TextButton.styleFrom(foregroundColor: AppStatusColors.onNeutralContainer),
                                  ),
                                ],

                              const Divider(height: 32),
                              const Text('تعيين مسؤول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 8),
                              if (state.agents.isEmpty)
                                const Text('لا يوجد مسؤولون', style: TextStyle(color: AppStatusColors.onNeutralContainer, fontSize: 12))
                              else
                                DropdownButtonFormField<String>(
                                  key: ValueKey(ticket.assignedAgentId),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    isDense: true,
                                  ),
                                  hint: const Text('اختر مسؤولاً'),
                                  initialValue: ticket.assignedAgentId,
                                  items: state.agents.map((a) {
                                    final id = a['user_id'] as String? ?? '';
                                    final role = a['role'] as String? ?? '';
                                    final name = a['name'] as String? ?? id.substring(0, 8);
                                    return DropdownMenuItem(value: id, child: Text('$name ($role)', style: const TextStyle(fontSize: 13)));
                                  }).toList(),
                                  onChanged: (agentId) {
                                    if (agentId == null) return;
                                    final agent = state.agents.firstWhere((a) => a['user_id'] == agentId, orElse: () => {});
                                    final name = agent['name'] as String? ?? agentId.substring(0, 8);
                                    cubit.assignAgent(agentId, name);
                                  },
                                ),

                              const Divider(height: 32),
                              const Text('ملاحظة داخلية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              if (ticket.internalNote != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppStatusColors.warningContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppStatusColors.onWarningContainer),
                                  ),
                                  child: Text(ticket.internalNote!),
                                ),
                                const SizedBox(height: 12),
                              ],
                              const Text('قوالب سريعة', style: TextStyle(fontSize: 12, color: AppStatusColors.onNeutralContainer)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: _kTemplates.map((t) => ActionChip(
                                  label: Text(t.title, style: const TextStyle(fontSize: 11)),
                                  onPressed: () {
                                    _noteController.text = t.body;
                                    _noteController.selection = TextSelection.collapsed(offset: t.body.length);
                                  },
                                )).toList(),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _noteController,
                                decoration: const InputDecoration(
                                  hintText: 'أضف أو عدّل الملاحظة الداخلية...',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  if (_noteController.text.trim().isNotEmpty) {
                                    cubit.saveInternalNote(_noteController.text.trim());
                                    _noteController.clear();
                                  }
                                },
                                child: const Text('حفظ الملاحظة'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ), // Closing ConstrainedBox
        );
      },
    );
  }
}
