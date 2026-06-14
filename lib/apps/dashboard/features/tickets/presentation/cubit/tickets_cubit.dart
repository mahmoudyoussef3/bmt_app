import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/complaint.dart';
import '../../domain/usecases/assign_complaint_usecase.dart';
import '../../domain/usecases/close_complaint_usecase.dart';
import '../../domain/usecases/delete_complaint_usecase.dart';
import '../../domain/usecases/escalate_complaint_usecase.dart';
import '../../domain/usecases/get_complaints_usecase.dart';
import '../../domain/usecases/respond_to_complaint_usecase.dart';
import '../../domain/usecases/update_complaint_status_usecase.dart';
import 'tickets_state.dart';

class TicketsCubit extends Cubit<TicketsState> {
  final GetComplaintsUseCase _getComplaints;
  final AssignComplaintUseCase _assignComplaint;
  final RespondToComplaintUseCase _respondToComplaint;
  final UpdateComplaintStatusUseCase _updateComplaintStatus;
  final EscalateComplaintUseCase _escalateComplaint;
  final CloseComplaintUseCase _closeComplaint;
  final DeleteComplaintUseCase _deleteComplaint;

  TicketsCubit({
    required GetComplaintsUseCase getComplaints,
    required AssignComplaintUseCase assignComplaint,
    required RespondToComplaintUseCase respondToComplaint,
    required UpdateComplaintStatusUseCase updateComplaintStatus,
    required EscalateComplaintUseCase escalateComplaint,
    required CloseComplaintUseCase closeComplaint,
    required DeleteComplaintUseCase deleteComplaint,
  })  : _getComplaints = getComplaints,
        _assignComplaint = assignComplaint,
        _respondToComplaint = respondToComplaint,
        _updateComplaintStatus = updateComplaintStatus,
        _escalateComplaint = escalateComplaint,
        _closeComplaint = closeComplaint,
        _deleteComplaint = deleteComplaint,
        super(const TicketsLoading());

  Future<void> load() async {
    emit(const TicketsLoading());
    try {
      final complaints = await _getComplaints();
      emit(
        TicketsLoaded(
          complaints: complaints,
          selectedComplaintId: complaints.isEmpty ? null : complaints.first.id,
        ),
      );
    } catch (error) {
      emit(TicketsError(error.toString()));
    }
  }

  void selectComplaint(String id) {
    final current = state;
    if (current is! TicketsLoaded) return;
    emit(current.copyWith(selectedComplaintId: id, clearMessage: true));
  }

  void setFilterStatus(ComplaintStatus? status) {
    final current = state;
    if (current is! TicketsLoaded) return;
    if (status == null) {
      emit(current.copyWith(clearStatusFilter: true));
    } else {
      emit(current.copyWith(filterStatus: status));
    }
  }

  void setFilterPriority(ComplaintPriority? priority) {
    final current = state;
    if (current is! TicketsLoaded) return;
    if (priority == null) {
      emit(current.copyWith(clearPriorityFilter: true));
    } else {
      emit(current.copyWith(filterPriority: priority));
    }
  }

  void setFilterCategory(ComplaintCategory? category) {
    final current = state;
    if (current is! TicketsLoaded) return;
    if (category == null) {
      emit(current.copyWith(clearCategoryFilter: true));
    } else {
      emit(current.copyWith(filterCategory: category));
    }
  }

  void setSearchQuery(String query) {
    final current = state;
    if (current is! TicketsLoaded) return;
    emit(current.copyWith(searchQuery: query));
  }

  Future<void> assign(String agentName) async {
    final current = state;
    if (current is! TicketsLoaded) return;
    final selectedId = current.selectedComplaintId;
    if (selectedId == null) return;

    emit(current.copyWith(actionLoading: true, clearMessage: true));
    try {
      final updated = await _assignComplaint(selectedId, agentName);
      _emitUpdated(current, updated, 'تم تعيين الشكوى إلى المسؤول: $agentName نجاح');
    } catch (error) {
      emit(current.copyWith(actionLoading: false, actionMessage: error.toString()));
    }
  }

  Future<void> respond(String content, {List<String> attachments = const []}) async {
    final normalized = content.trim();
    if (normalized.isEmpty && attachments.isEmpty) return;

    final current = state;
    if (current is! TicketsLoaded) return;
    final selectedId = current.selectedComplaintId;
    if (selectedId == null) return;

    emit(current.copyWith(actionLoading: true, clearMessage: true));
    try {
      final updated = await _respondToComplaint(
        selectedId,
        senderName: current.selectedComplaint?.assignedTo ?? 'الدعم الفني',
        senderType: 'agent',
        content: normalized,
        attachments: attachments,
      );
      _emitUpdated(current, updated, 'تم إرسال الرد بنجاح');
    } catch (error) {
      emit(current.copyWith(actionLoading: false, actionMessage: error.toString()));
    }
  }

  Future<void> updateStatus(ComplaintStatus status) async {
    final current = state;
    if (current is! TicketsLoaded) return;
    final selectedId = current.selectedComplaintId;
    if (selectedId == null) return;

    emit(current.copyWith(actionLoading: true, clearMessage: true));
    try {
      final updated = await _updateComplaintStatus(selectedId, status);
      _emitUpdated(current, updated, 'تم تحديث حالة الشكوى إلى: ${status.label}');
    } catch (error) {
      emit(current.copyWith(actionLoading: false, actionMessage: error.toString()));
    }
  }

  Future<void> escalate() async {
    final current = state;
    if (current is! TicketsLoaded) return;
    final selectedId = current.selectedComplaintId;
    if (selectedId == null) return;

    emit(current.copyWith(actionLoading: true, clearMessage: true));
    try {
      final updated = await _escalateComplaint(selectedId);
      _emitUpdated(current, updated, 'تم تصعيد الشكوى وتغيير الأولوية إلى حرجة');
    } catch (error) {
      emit(current.copyWith(actionLoading: false, actionMessage: error.toString()));
    }
  }

  Future<void> closeComplaint() async {
    final current = state;
    if (current is! TicketsLoaded) return;
    final selectedId = current.selectedComplaintId;
    if (selectedId == null) return;

    emit(current.copyWith(actionLoading: true, clearMessage: true));
    try {
      final updated = await _closeComplaint(selectedId);
      _emitUpdated(current, updated, 'تم إغلاق الشكوى نهائياً');
    } catch (error) {
      emit(current.copyWith(actionLoading: false, actionMessage: error.toString()));
    }
  }

  Future<void> deleteComplaint() async {
    final current = state;
    if (current is! TicketsLoaded) return;
    final selectedId = current.selectedComplaintId;
    if (selectedId == null) return;

    emit(current.copyWith(actionLoading: true, clearMessage: true));
    try {
      await _deleteComplaint(selectedId);
      
      final list = current.complaints.where((c) => c.id != selectedId).toList();
      emit(
        current.copyWith(
          complaints: list,
          selectedComplaintId: list.isEmpty ? null : list.first.id,
          actionLoading: false,
          actionMessage: 'تم حذف الشكوى بنجاح',
        ),
      );
    } catch (error) {
      emit(current.copyWith(actionLoading: false, actionMessage: error.toString()));
    }
  }

  void clearActionMessage() {
    final current = state;
    if (current is TicketsLoaded) {
      emit(current.copyWith(clearMessage: true));
    }
  }

  void _emitUpdated(TicketsLoaded current, Complaint updated, String successMessage) {
    final list = current.complaints
        .map((c) => c.id == updated.id ? updated : c)
        .toList();
    emit(
      current.copyWith(
        complaints: list,
        selectedComplaintId: updated.id,
        actionLoading: false,
        actionMessage: successMessage,
      ),
    );
  }
}
