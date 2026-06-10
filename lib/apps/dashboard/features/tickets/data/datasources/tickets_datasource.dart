import '../../domain/entities/complaint.dart';

abstract class TicketsDatasource {
  Future<List<Complaint>> getComplaints();
  Future<Complaint> assignComplaint(String id, String agentName);
  Future<Complaint> respondToComplaint(
    String id, {
    required String senderName,
    required String senderType,
    required String content,
    required List<String> attachments,
  });
  Future<Complaint> updateComplaintStatus(String id, ComplaintStatus status);
  Future<Complaint> escalateComplaint(String id);
  Future<Complaint> closeComplaint(String id);
}

class MockTicketsDatasource implements TicketsDatasource {
  MockTicketsDatasource() {
    _complaints = _generateMockComplaints();
  }

  late List<Complaint> _complaints;

  @override
  Future<List<Complaint>> getComplaints() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<Complaint>.from(_complaints);
  }

  @override
  Future<Complaint> assignComplaint(String id, String agentName) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final index = _findIndex(id);
    final complaint = _complaints[index];

    final updated = complaint.copyWith(
      assignedTo: agentName,
      history: [
        ...complaint.history,
        ComplaintLog(
          id: 'log-${DateTime.now().millisecondsSinceEpoch}',
          action: 'تم تعيين الشكوى إلى المسؤول: $agentName',
          timestamp: DateTime.now(),
          actor: 'النظام',
        ),
      ],
    );
    _complaints[index] = updated;
    return updated;
  }

  @override
  Future<Complaint> respondToComplaint(
    String id, {
    required String senderName,
    required String senderType,
    required String content,
    required List<String> attachments,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final index = _findIndex(id);
    final complaint = _complaints[index];

    final newMessage = ComplaintMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderName: senderName,
      senderType: senderType,
      content: content,
      timestamp: DateTime.now(),
      attachments: attachments,
    );

    // If agent responds, we automatically set status to waitingForClient
    var newStatus = complaint.status;
    if (senderType == 'agent' && complaint.status == ComplaintStatus.newlyCreated || complaint.status == ComplaintStatus.inProgress) {
      newStatus = ComplaintStatus.waitingForClient;
    }

    final updated = complaint.copyWith(
      status: newStatus,
      conversation: [...complaint.conversation, newMessage],
      history: [
        ...complaint.history,
        ComplaintLog(
          id: 'log-${DateTime.now().millisecondsSinceEpoch}',
          action: 'تم إرسال رد من قبل $senderName',
          timestamp: DateTime.now(),
          actor: senderName,
        ),
      ],
    );
    _complaints[index] = updated;
    return updated;
  }

  @override
  Future<Complaint> updateComplaintStatus(String id, ComplaintStatus status) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final index = _findIndex(id);
    final complaint = _complaints[index];

    final updated = complaint.copyWith(
      status: status,
      history: [
        ...complaint.history,
        ComplaintLog(
          id: 'log-${DateTime.now().millisecondsSinceEpoch}',
          action: 'تم تغيير حالة الشكوى إلى: ${status.label}',
          timestamp: DateTime.now(),
          actor: 'المسؤول',
        ),
      ],
    );
    _complaints[index] = updated;
    return updated;
  }

  @override
  Future<Complaint> escalateComplaint(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final index = _findIndex(id);
    final complaint = _complaints[index];

    final updated = complaint.copyWith(
      priority: ComplaintPriority.critical,
      history: [
        ...complaint.history,
        ComplaintLog(
          id: 'log-${DateTime.now().millisecondsSinceEpoch}',
          action: 'تم تصعيد الشكوى وتغيير الأولوية إلى حرجة',
          timestamp: DateTime.now(),
          actor: 'المسؤول',
        ),
      ],
    );
    _complaints[index] = updated;
    return updated;
  }

  @override
  Future<Complaint> closeComplaint(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final index = _findIndex(id);
    final complaint = _complaints[index];

    final updated = complaint.copyWith(
      status: ComplaintStatus.closed,
      history: [
        ...complaint.history,
        ComplaintLog(
          id: 'log-${DateTime.now().millisecondsSinceEpoch}',
          action: 'تم إغلاق الشكوى نهائياً',
          timestamp: DateTime.now(),
          actor: 'المسؤول',
        ),
      ],
    );
    _complaints[index] = updated;
    return updated;
  }

  int _findIndex(String id) {
    final idx = _complaints.indexWhere((c) => c.id == id);
    if (idx == -1) throw Exception('الشكوى غير موجودة');
    return idx;
  }

  List<Complaint> _generateMockComplaints() {
    final list = <Complaint>[];
    final now = DateTime.now();

    final names = [
      'أحمد المصرى', 'منى الشافعى', 'عمر الخطيب', 'رنا السعيد', 'كريم حسن',
      'ياسمين ممدوح', 'محمود يوسف', 'سارة الجيار', 'خالد النجار', 'فاطمة الزهراء',
      'يوسف الشريف', 'مروة عبد العزيز', 'مصطفى كامل', 'هند رسلان', 'شريف منير'
    ];

    final clientPhones = [
      '01012345678', '01123456789', '01234567890', '01545678901', '01098765432'
    ];

    final categories = ComplaintCategory.values;
    final priorities = ComplaintPriority.values;
    final statuses = ComplaintStatus.values;

    final tripCodes = [
      'TR-8812', 'TR-1024', 'TR-4821', 'TR-7391', 'TR-9231', 'TR-3310', 'TR-5521'
    ];

    final categoryDescriptions = {
      ComplaintCategory.tripDelay: 'تأخرت الحافلة لأكثر من ٣٠ دقيقة عن الموعد المحدد، مما تسبب في تأخري عن العمل المهم.',
      ComplaintCategory.driverBehavior: 'كان السائق يقود بسرعة جنونية وتحدث بنبرة غير لائقة عندما طلبت منه التخفيف.',
      ComplaintCategory.vehicleCleanliness: 'المقاعد كانت متسخة جداً وهناك رائحة كريهة داخل الباص طوال الرحلة.',
      ComplaintCategory.appIssue: 'حاولت الحجز عبر التطبيق وتم خصم المبلغ مرتين ولم يظهر الحجز في قائمة رحلاتي.',
      ComplaintCategory.lostItem: 'نسيت حقيبتي السوداء الصغيرة وبها متعلقات شخصية على المقعد رقم ١٢ بالرحلة.',
      ComplaintCategory.paymentIssue: 'تم الخصم من المحفظة الإلكترونية ولم يتم تفعيل الكود الخاص بالخصم الممنوح لي.',
      ComplaintCategory.other: 'أقترح إضافة خط باص جديد يربط مباشرة بين بنها والتجمع الخامس لخدمة الطلاب والموظفين.',
    };

    final categoryResponses = {
      ComplaintCategory.tripDelay: 'نعتذر جداً عن التأخير، الكثافة المرورية العالية كانت السبب وسنقوم بتعويضك بنقاط مجانية.',
      ComplaintCategory.driverBehavior: 'تم تحويل الشكوى لإدارة الحركة وتم التنبيه على السائق وإحالته للتحقيق والتدريب السلوكي.',
      ComplaintCategory.vehicleCleanliness: 'نشكرك على التنبيه، تم إرسال الباص للتنظيف الدوري والتعقيم وسيتم متابعة المشرف المسؤول.',
      ComplaintCategory.appIssue: 'تم التحقق من العملية وجاري استرجاع المبلغ الزائد لمحفظتك الإلكترونية خلال ٢٤ ساعة.',
      ComplaintCategory.lostItem: 'تم العثور على حقيبتك من قبل السائق وهي متوفرة الآن بفرع الشركة الرئيسي للاستلام.',
      ComplaintCategory.paymentIssue: 'تم معالجة المشكلة وإعادة قيمة الخصم لحسابك، ونعتذر عن هذا الخطأ التقني.',
      ComplaintCategory.other: 'شكراً لمقترحك القيم، تم رفعه لقسم التخطيط لدراسة جدوى الخط الجديد.',
    };

    final agents = ['عادل إمام', 'ريهام سعيد', 'هشام الجخ', 'ياسر جلال'];

    for (int i = 1; i <= 102; i++) {
      final id = 'COMP-${1000 + i}';
      final clientName = names[i % names.length];
      final clientPhone = clientPhones[i % clientPhones.length];
      final category = categories[i % categories.length];
      final tripCode = tripCodes[i % tripCodes.length];
      final priority = priorities[i % priorities.length];
      final status = statuses[i % statuses.length];
      final description = categoryDescriptions[category] ?? 'تفاصيل الشكوى';

      // Distribute creation dates between 1 to 15 days ago
      final createdDaysAgo = (i % 15) + 1;
      final createdHoursAgo = i % 24;
      final createdAt = now.subtract(Duration(days: createdDaysAgo, hours: createdHoursAgo));

      // Build conversation history based on status
      final conversation = <ComplaintMessage>[];
      // Message 1: Initial complaint from client
      conversation.add(
        ComplaintMessage(
          id: 'msg-init-$i',
          senderName: clientName,
          senderType: 'client',
          content: description,
          timestamp: createdAt,
          attachments: i % 4 == 0 ? ['screenshot_$i.jpg'] : [],
        ),
      );

      final assignedTo = status == ComplaintStatus.newlyCreated
          ? null
          : agents[i % agents.length];

      final history = <ComplaintLog>[
        ComplaintLog(
          id: 'log-init-$i',
          action: 'تم تقديم الشكوى بنجاح عبر التطبيق',
          timestamp: createdAt,
          actor: clientName,
        ),
      ];

      if (status != ComplaintStatus.newlyCreated) {
        final assignTime = createdAt.add(const Duration(minutes: 45));
        history.add(
          ComplaintLog(
            id: 'log-assign-$i',
            action: 'تم تعيين الشكوى للمسؤول $assignedTo',
            timestamp: assignTime,
            actor: 'النظام',
          ),
        );

        if (status == ComplaintStatus.inProgress ||
            status == ComplaintStatus.waitingForClient ||
            status == ComplaintStatus.resolved ||
            status == ComplaintStatus.closed) {
          final replyTime = createdAt.add(const Duration(hours: 2));
          conversation.add(
            ComplaintMessage(
              id: 'msg-reply-agent-$i',
              senderName: assignedTo ?? 'الدعم الفني',
              senderType: 'agent',
              content: 'أهلاً بك يا فندم. ${categoryResponses[category]}',
              timestamp: replyTime,
              attachments: const [],
            ),
          );
          history.add(
            ComplaintLog(
              id: 'log-reply-$i',
              action: 'تم الرد من قبل الدعم الفني وتوضيح الموقف',
              timestamp: replyTime,
              actor: assignedTo ?? 'الدعم الفني',
            ),
          );

          if (status == ComplaintStatus.waitingForClient ||
              status == ComplaintStatus.resolved ||
              status == ComplaintStatus.closed) {
            final clientResponseTime = createdAt.add(const Duration(hours: 4));
            conversation.add(
              ComplaintMessage(
                id: 'msg-reply-client-$i',
                senderName: clientName,
                senderType: 'client',
                content: status == ComplaintStatus.waitingForClient
                    ? 'شكراً لتوضيحكم، ولكن هل سيتم محاسبة السائق فعلياً؟'
                    : 'شكراً جزيلاً لكم على سرعة الاستجابة وحل المشكلة بشكل ممتاز.',
                timestamp: clientResponseTime,
                attachments: const [],
              ),
            );
            history.add(
              ComplaintLog(
                id: 'log-reply-client-history-$i',
                action: 'تم تحديث التذكرة برد من العميل',
                timestamp: clientResponseTime,
                actor: clientName,
              ),
            );

            if (status == ComplaintStatus.resolved || status == ComplaintStatus.closed) {
              final resolveTime = createdAt.add(const Duration(hours: 6));
              history.add(
                ComplaintLog(
                  id: 'log-resolve-$i',
                  action: 'تم إغلاق المشكلة وتأكيد الحل مع العميل',
                  timestamp: resolveTime,
                  actor: assignedTo ?? 'الدعم الفني',
                ),
              );

              if (status == ComplaintStatus.closed) {
                final closeTime = createdAt.add(const Duration(hours: 24));
                history.add(
                  ComplaintLog(
                    id: 'log-close-$i',
                    action: 'تم إغلاق التذكرة نهائياً لعدم وجود استفسارات إضافية',
                    timestamp: closeTime,
                    actor: 'النظام',
                  ),
                );
              }
            }
          }
        }
      }

      list.add(
        Complaint(
          id: id,
          clientName: clientName,
          clientPhone: clientPhone,
          category: category,
          tripCode: tripCode,
          createdAt: createdAt,
          assignedTo: assignedTo,
          status: status,
          priority: priority,
          description: description,
          conversation: conversation,
          attachments: i % 4 == 0 ? ['screenshot_$i.jpg'] : [],
          history: history,
        ),
      );
    }

    return list;
  }
}
