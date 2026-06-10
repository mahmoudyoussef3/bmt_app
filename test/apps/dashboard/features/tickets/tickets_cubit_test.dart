import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/tickets/domain/entities/complaint.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/assign_complaint_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/close_complaint_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/escalate_complaint_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/get_complaints_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/respond_to_complaint_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/update_complaint_status_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/presentation/cubit/tickets_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/presentation/cubit/tickets_state.dart';

void main() {
  group('TicketsCubit tests', () {
    late _MockTicketsRepository repository;
    late TicketsCubit cubit;

    setUp(() {
      repository = _MockTicketsRepository();
      cubit = TicketsCubit(
        getComplaints: GetComplaintsUseCase(repository),
        assignComplaint: AssignComplaintUseCase(repository),
        respondToComplaint: RespondToComplaintUseCase(repository),
        updateComplaintStatus: UpdateComplaintStatusUseCase(repository),
        escalateComplaint: EscalateComplaintUseCase(repository),
        closeComplaint: CloseComplaintUseCase(repository),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is TicketsLoading', () {
      expect(cubit.state, isA<TicketsLoading>());
    });

    test('load() success emits TicketsLoaded with complaints', () async {
      await cubit.load();

      expect(cubit.state, isA<TicketsLoaded>());
      final loaded = cubit.state as TicketsLoaded;
      expect(loaded.complaints, isNotEmpty);
      expect(loaded.selectedComplaintId, 'COMP-1001');
    });

    test('selectComplaint() updates selected ID', () async {
      await cubit.load();
      cubit.selectComplaint('COMP-1002');

      final loaded = cubit.state as TicketsLoaded;
      expect(loaded.selectedComplaintId, 'COMP-1002');
    });

    test('assign() updates assignedTo field', () async {
      await cubit.load();
      await cubit.assign('ريهام سعيد');

      final loaded = cubit.state as TicketsLoaded;
      expect(loaded.selectedComplaint?.assignedTo, 'ريهام سعيد');
    });

    test('respond() adds a message', () async {
      await cubit.load();
      await cubit.respond('شكراً للمتابعة');

      final loaded = cubit.state as TicketsLoaded;
      expect(loaded.selectedComplaint?.conversation.length, 3);
      expect(loaded.selectedComplaint?.conversation.last.content, 'شكراً للمتابعة');
    });

    test('updateStatus() updates status badge', () async {
      await cubit.load();
      await cubit.updateStatus(ComplaintStatus.resolved);

      final loaded = cubit.state as TicketsLoaded;
      expect(loaded.selectedComplaint?.status, ComplaintStatus.resolved);
    });

    test('escalate() sets priority to critical', () async {
      await cubit.load();
      await cubit.escalate();

      final loaded = cubit.state as TicketsLoaded;
      expect(loaded.selectedComplaint?.priority, ComplaintPriority.critical);
    });

    test('closeComplaint() sets status to closed', () async {
      await cubit.load();
      await cubit.closeComplaint();

      final loaded = cubit.state as TicketsLoaded;
      expect(loaded.selectedComplaint?.status, ComplaintStatus.closed);
    });
  });
}

class _MockTicketsRepository implements TicketsRepository {
  List<Complaint> complaints = [
    Complaint(
      id: 'COMP-1001',
      clientName: 'أحمد المصرى',
      clientPhone: '01012345678',
      category: ComplaintCategory.tripDelay,
      tripCode: 'TR-1024',
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
      status: ComplaintStatus.newlyCreated,
      priority: ComplaintPriority.medium,
      description: 'تأخرت الحافلة لأكثر من ٣٠ دقيقة.',
      conversation: [
        ComplaintMessage(
          id: 'm1',
          senderName: 'أحمد المصرى',
          senderType: 'client',
          content: 'تأخرت الحافلة لأكثر من ٣٠ دقيقة.',
          timestamp: DateTime.now().subtract(const Duration(hours: 10)),
          attachments: const [],
        ),
        ComplaintMessage(
          id: 'm2',
          senderName: 'الدعم الفني',
          senderType: 'agent',
          content: 'نعتذر جداً عن التأخير.',
          timestamp: DateTime.now().subtract(const Duration(hours: 9)),
          attachments: const [],
        ),
      ],
      attachments: const [],
      history: const [],
    ),
    Complaint(
      id: 'COMP-1002',
      clientName: 'منى الشافعى',
      clientPhone: '01123456789',
      category: ComplaintCategory.driverBehavior,
      tripCode: 'TR-7391',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      status: ComplaintStatus.inProgress,
      priority: ComplaintPriority.high,
      description: 'كان السائق يقود بسرعة جنونية.',
      conversation: const [],
      attachments: const [],
      history: const [],
    ),
  ];

  @override
  Future<List<Complaint>> getComplaints() async => complaints;

  @override
  Future<Complaint> assignComplaint(String id, String agentName) async {
    final idx = complaints.indexWhere((c) => c.id == id);
    final updated = complaints[idx].copyWith(assignedTo: agentName);
    complaints[idx] = updated;
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
    final idx = complaints.indexWhere((c) => c.id == id);
    final updated = complaints[idx].copyWith(
      conversation: [
        ...complaints[idx].conversation,
        ComplaintMessage(
          id: 'new-msg',
          senderName: senderName,
          senderType: senderType,
          content: content,
          timestamp: DateTime.now(),
          attachments: attachments,
        ),
      ],
    );
    complaints[idx] = updated;
    return updated;
  }

  @override
  Future<Complaint> updateComplaintStatus(String id, ComplaintStatus status) async {
    final idx = complaints.indexWhere((c) => c.id == id);
    final updated = complaints[idx].copyWith(status: status);
    complaints[idx] = updated;
    return updated;
  }

  @override
  Future<Complaint> escalateComplaint(String id) async {
    final idx = complaints.indexWhere((c) => c.id == id);
    final updated = complaints[idx].copyWith(priority: ComplaintPriority.critical);
    complaints[idx] = updated;
    return updated;
  }

  @override
  Future<Complaint> closeComplaint(String id) async {
    final idx = complaints.indexWhere((c) => c.id == id);
    final updated = complaints[idx].copyWith(status: ComplaintStatus.closed);
    complaints[idx] = updated;
    return updated;
  }
}
