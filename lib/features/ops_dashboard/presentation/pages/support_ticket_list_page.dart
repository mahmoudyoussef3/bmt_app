import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import '../widgets/status_chip.dart';

class _SupportTicketItem {
  final String id;
  final String customerName;
  final String complaintType;
  final DateTime createdAt;
  final String priority;
  String status;
  String? assignedAgent;
  final String details;
  final String? attachmentName;

  _SupportTicketItem({
    required this.id,
    required this.customerName,
    required this.complaintType,
    required this.createdAt,
    required this.priority,
    required this.status,
    required this.details,
    this.assignedAgent,
    this.attachmentName,
  });
}

String _arabicDigits(Object value) {
  const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var text = value.toString();
  for (var i = 0; i < western.length; i++) {
    text = text.replaceAll(western[i], arabic[i]);
  }
  return text;
}

String _complaintNumber(String id) {
  final digits = id.replaceAll(RegExp('[^0-9]'), '');
  return _arabicDigits(digits);
}

class SupportTicketListPage extends StatefulWidget {
  const SupportTicketListPage({super.key});

  @override
  State<SupportTicketListPage> createState() => _SupportTicketListPageState();
}

class _SupportTicketListPageState extends State<SupportTicketListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<String> _tabs = const [
    'جديدة',
    'قيد المراجعة',
    'تم الحل',
    'مغلقة',
  ];

  final List<String> _agents = const [
    'أحمد محمود',
    'ندى خالد',
    'كريم حسن',
    'سارة علي',
  ];

  final List<_SupportTicketItem> _tickets = [
    _SupportTicketItem(
      id: 'SC-1001',
      customerName: 'خالد محمود',
      complaintType: 'مشكلة دفع',
      createdAt: DateTime(2026, 6, 5, 9, 15),
      priority: 'عاجل',
      status: 'جديدة',
      details: 'تم خصم المبلغ ولم يظهر الحجز في حساب العميل.',
      attachmentName: 'إيصال التحويل',
    ),
    _SupportTicketItem(
      id: 'SC-1002',
      customerName: 'رنا يوسف',
      complaintType: 'تغيير موعد',
      createdAt: DateTime(2026, 6, 5, 9, 42),
      priority: 'متوسط',
      status: 'جديدة',
      details: 'تحتاج نقل الحجز إلى رحلة لاحقة اليوم.',
    ),
    _SupportTicketItem(
      id: 'SC-1003',
      customerName: 'طارق محمد',
      complaintType: 'سائق متأخر',
      createdAt: DateTime(2026, 6, 5, 8, 30),
      priority: 'عاجل',
      status: 'قيد المراجعة',
      assignedAgent: 'ندى خالد',
      details: 'العميل ينتظر تحديثاً سريعاً عن مكان السائق.',
      attachmentName: 'صورة المحادثة',
    ),
    _SupportTicketItem(
      id: 'SC-1004',
      customerName: 'سارة أحمد',
      complaintType: 'استرداد مبلغ',
      createdAt: DateTime(2026, 6, 4, 18, 10),
      priority: 'متوسط',
      status: 'قيد المراجعة',
      assignedAgent: 'أحمد محمود',
      details: 'طلب استرداد بعد إلغاء رحلة من طرف التشغيل.',
    ),
    _SupportTicketItem(
      id: 'SC-1005',
      customerName: 'عمر فاروق',
      complaintType: 'استفسار اشتراك',
      createdAt: DateTime(2026, 6, 4, 14, 25),
      priority: 'منخفض',
      status: 'تم الحل',
      assignedAgent: 'كريم حسن',
      details: 'تم توضيح تاريخ تجديد الاشتراك ورصيد المحفظة.',
    ),
    _SupportTicketItem(
      id: 'SC-1006',
      customerName: 'ياسمين علي',
      complaintType: 'مقعد غير صحيح',
      createdAt: DateTime(2026, 6, 3, 11, 5),
      priority: 'منخفض',
      status: 'مغلقة',
      assignedAgent: 'سارة علي',
      details: 'تم تصحيح المقعد وإغلاق الشكوى بعد تأكيد العميل.',
      attachmentName: 'تذكرة الحجز',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_SupportTicketItem> _ticketsFor(String status) {
    return _tickets.where((ticket) => ticket.status == status).toList();
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'عاجل':
        return Colors.red.shade400;
      case 'متوسط':
        return Colors.orange.shade300;
      case 'منخفض':
        return Colors.green.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'جديدة':
        return Colors.cyan.shade300;
      case 'قيد المراجعة':
        return Colors.orange.shade300;
      case 'تم الحل':
        return Colors.green.shade400;
      case 'مغلقة':
        return Colors.grey.shade400;
      default:
        return Colors.blueGrey.shade300;
    }
  }

  String _formatDate(DateTime date) {
    final day = _arabicDigits(date.day.toString().padLeft(2, '0'));
    final month = _arabicDigits(date.month.toString().padLeft(2, '0'));
    final hour = _arabicDigits(date.hour.toString().padLeft(2, '0'));
    final minute = _arabicDigits(date.minute.toString().padLeft(2, '0'));
    return '$day/$month - $hour:$minute';
  }

  void _showActionToast(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(label),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _assignTicket(_SupportTicketItem ticket) {
    showDialog(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تعيين الشكوى ${_complaintNumber(ticket.id)}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _agents.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final agent = _agents[index];
                  final isCurrent = ticket.assignedAgent == agent;

                  return ListTile(
                    leading: Icon(
                      Icons.support_agent_rounded,
                      color: isCurrent
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.55),
                    ),
                    title: Text(agent),
                    trailing: isCurrent
                        ? Icon(Icons.check_rounded, color: scheme.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        ticket.assignedAgent = agent;
                        if (ticket.status == 'جديدة') {
                          ticket.status = 'قيد المراجعة';
                          _tabController.index = 1;
                        }
                      });
                      Navigator.pop(context);
                      _showActionToast('تم تعيين الشكوى إلى $agent');
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _replyToTicket(_SupportTicketItem ticket) {
    final replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('الرد على الشكوى ${_complaintNumber(ticket.id)}'),
            content: TextField(
              controller: replyController,
              minLines: 4,
              maxLines: 6,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'نص الرد',
                alignLabelWithHint: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showActionToast(
                    'تم إرسال الرد للعميل ${ticket.customerName}',
                  );
                },
                child: const Text('إرسال الرد'),
              ),
            ],
          ),
        );
      },
    ).whenComplete(replyController.dispose);
  }

  void _closeTicket(_SupportTicketItem ticket) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('إغلاق الشكوى ${_complaintNumber(ticket.id)}'),
            content: const Text('سيتم نقل الشكوى إلى تبويب مغلقة.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('تراجع'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    ticket.status = 'مغلقة';
                    _tabController.index = 3;
                  });
                  Navigator.pop(context);
                  _showActionToast('تم إغلاق الشكوى');
                },
                child: const Text('إغلاق الشكوى'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مركز الدعم'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () => _showActionToast('تم تحديث قائمة الشكاوى'),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _tabs.map((status) {
              final count = _ticketsFor(status).length;
              return Tab(text: '$status (${_arabicDigits(count)})');
            }).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map((status) {
            final tickets = _ticketsFor(status);
            return _TicketStatusList(
              tickets: tickets,
              statusColor: _statusColor(status),
              priorityColor: _priorityColor,
              formatDate: _formatDate,
              onAssign: _assignTicket,
              onReply: _replyToTicket,
              onClose: _closeTicket,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TicketStatusList extends StatelessWidget {
  final List<_SupportTicketItem> tickets;
  final Color statusColor;
  final Color Function(String priority) priorityColor;
  final String Function(DateTime date) formatDate;
  final void Function(_SupportTicketItem ticket) onAssign;
  final void Function(_SupportTicketItem ticket) onReply;
  final void Function(_SupportTicketItem ticket) onClose;

  const _TicketStatusList({
    required this.tickets,
    required this.statusColor,
    required this.priorityColor,
    required this.formatDate,
    required this.onAssign,
    required this.onReply,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (tickets.isEmpty) {
      return Center(
        child: Text(
          'لا توجد شكاوى في هذا التبويب',
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.62),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? AppSpacing.xLarge : AppSpacing.medium,
            vertical: AppSpacing.medium,
          ),
          itemCount: tickets.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.medium),
          itemBuilder: (context, index) {
            return _TicketCard(
              ticket: tickets[index],
              statusColor: statusColor,
              priorityColor: priorityColor(tickets[index].priority),
              createdAtText: formatDate(tickets[index].createdAt),
              onAssign: () => onAssign(tickets[index]),
              onReply: () => onReply(tickets[index]),
              onClose: tickets[index].status == 'مغلقة'
                  ? null
                  : () => onClose(tickets[index]),
            );
          },
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final _SupportTicketItem ticket;
  final Color statusColor;
  final Color priorityColor;
  final String createdAtText;
  final VoidCallback onAssign;
  final VoidCallback onReply;
  final VoidCallback? onClose;

  const _TicketCard({
    required this.ticket,
    required this.statusColor,
    required this.priorityColor,
    required this.createdAtText,
    required this.onAssign,
    required this.onReply,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: AppTokens.cardElevation,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                CircleAvatar(
                  radius: 21,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    ticket.customerName[0],
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket.complaintType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.62),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                _PriorityBadge(label: ticket.priority, color: priorityColor),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                _TicketFact(
                  icon: Icons.confirmation_number_rounded,
                  label: 'رقم الشكوى',
                  value: _complaintNumber(ticket.id),
                ),
                _TicketFact(
                  icon: Icons.person_rounded,
                  label: 'اسم العميل',
                  value: ticket.customerName,
                ),
                _TicketFact(
                  icon: Icons.category_rounded,
                  label: 'نوع الشكوى',
                  value: ticket.complaintType,
                ),
                _TicketFact(
                  icon: Icons.schedule_rounded,
                  label: 'تاريخ الإنشاء',
                  value: createdAtText,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              ticket.details,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.76),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (ticket.attachmentName != null) ...[
              const SizedBox(height: AppSpacing.medium),
              _AttachmentPreview(name: ticket.attachmentName!),
            ],
            const SizedBox(height: AppSpacing.medium),
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.assignedAgent == null
                        ? 'غير معينة لموظف'
                        : 'الموظف: ${ticket.assignedAgent}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.58),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                StatusChip(label: ticket.status, color: statusColor),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                _TicketActionButton(
                  label: 'تعيين لموظف',
                  icon: Icons.assignment_ind_rounded,
                  onPressed: onAssign,
                  isPrimary: true,
                ),
                _TicketActionButton(
                  label: 'الرد',
                  icon: Icons.reply_rounded,
                  onPressed: onReply,
                ),
                _TicketActionButton(
                  label: 'إغلاق الشكوى',
                  icon: Icons.lock_rounded,
                  onPressed: onClose,
                  isDestructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PriorityBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TicketFact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TicketFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 155),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.56),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final String name;

  const _AttachmentPreview({required this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.attach_file_rounded,
              size: 18,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مرفق',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              Text(
                name,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TicketActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const _TicketActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isDestructive ? scheme.error : scheme.primary;

    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        foregroundColor: color,
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.32),
        side: BorderSide(
          color: onPressed == null
              ? scheme.outline.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.38),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
      ),
    );
  }
}
