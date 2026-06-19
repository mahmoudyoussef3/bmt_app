import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/complaint.dart';
import '../../domain/usecases/assign_agent_usecase.dart';
import '../../domain/usecases/get_tickets_usecase.dart';
import '../../domain/usecases/update_ticket_status_usecase.dart';
import '../../domain/usecases/save_internal_note_usecase.dart';
import '../../domain/usecases/mark_customer_contacted_usecase.dart';
import '../../domain/usecases/close_ticket_usecase.dart';
import '../../domain/usecases/get_ticket_attachments_usecase.dart';
import 'tickets_state.dart';

class TicketsCubit extends Cubit<TicketsState> {
  final GetTicketsUseCase _getTickets;
  final UpdateTicketStatusUseCase _updateTicketStatus;
  final SaveInternalNoteUseCase _saveInternalNote;
  final MarkCustomerContactedUseCase _markCustomerContacted;
  final CloseTicketUseCase _closeTicket;
  final GetTicketAttachmentsUseCase _getTicketAttachments;
  final AssignAgentUseCase _assignAgent;
  final GetAgentsUseCase _getAgents;

  TicketsCubit({
    required GetTicketsUseCase getTickets,
    required UpdateTicketStatusUseCase updateTicketStatus,
    required SaveInternalNoteUseCase saveInternalNote,
    required MarkCustomerContactedUseCase markCustomerContacted,
    required CloseTicketUseCase closeTicket,
    required GetTicketAttachmentsUseCase getTicketAttachments,
    required AssignAgentUseCase assignAgent,
    required GetAgentsUseCase getAgents,
  }) : _getTickets = getTickets,
       _updateTicketStatus = updateTicketStatus,
       _saveInternalNote = saveInternalNote,
       _markCustomerContacted = markCustomerContacted,
       _closeTicket = closeTicket,
       _getTicketAttachments = getTicketAttachments,
       _assignAgent = assignAgent,
       _getAgents = getAgents,
       super(const TicketsLoading());

  Future<void> load() async {
    emit(const TicketsLoading());
    try {
      final results = await Future.wait([_getTickets(), _getAgents()]);
      emit(
        TicketsLoaded(
          tickets: results[0] as List<SupportTicket>,
          agents: results[1] as List<Map<String, dynamic>>,
        ),
      );
    } catch (error) {
      emit(TicketsError(error.toString()));
    }
  }

  Future<void> assignAgent(String agentId, String agentName) async {
    final current = state;
    if (current is! TicketsLoaded) return;
    final selectedId = current.selectedTicketId;
    if (selectedId == null) return;
    emit(current.copyWith(actionLoading: true));
    try {
      final updated = await _assignAgent(selectedId, agentId, agentName);
      _emitUpdated(
        current.copyWith(agents: current.agents),
        updated,
        'Assigned to $agentName',
      );
    } catch (error) {
      emit(
        current.copyWith(actionLoading: false, actionMessage: error.toString()),
      );
    }
  }

  Future<void> selectTicket(String id) async {
    final current = state;
    if (current is! TicketsLoaded) return;

    emit(current.copyWith(selectedTicketId: id));

    try {
      final attachments = await _getTicketAttachments(id);
      if (state is TicketsLoaded &&
          (state as TicketsLoaded).selectedTicketId == id) {
        emit(
          (state as TicketsLoaded).copyWith(
            selectedTicketAttachments: attachments,
          ),
        );
      }
    } catch (e, stack) {
      developer.log(
        'Failed to load attachments',
        error: e,
        stackTrace: stack,
        name: 'TicketsCubit',
      );
    }
  }

  void setFilterStatus(TicketStatus? status) {
    final current = state;
    if (current is! TicketsLoaded) return;
    emit(
      current.copyWith(filterStatus: status, clearFilterStatus: status == null),
    );
  }

  void setFilterPriority(TicketPriority? priority) {
    final current = state;
    if (current is! TicketsLoaded) return;
    emit(
      current.copyWith(
        filterPriority: priority,
        clearFilterPriority: priority == null,
      ),
    );
  }

  void setSearchQuery(String query) {
    final current = state;
    if (current is! TicketsLoaded) return;
    emit(current.copyWith(searchQuery: query));
  }

  Future<void> updateStatus(TicketStatus status) async {
    final current = state;
    if (current is! TicketsLoaded) return;
    final selectedId = current.selectedTicketId;
    if (selectedId == null) return;

    emit(current.copyWith(actionLoading: true));
    try {
      final updated = await _updateTicketStatus(selectedId, status);
      _emitUpdated(
        current,
        updated,
        'Ticket status updated to ${status.label}',
      );
    } catch (error) {
      emit(
        current.copyWith(actionLoading: false, actionMessage: error.toString()),
      );
    }
  }

  Future<void> saveInternalNote(String note) async {
    final current = state;
    if (current is! TicketsLoaded) return;
    final selectedId = current.selectedTicketId;
    if (selectedId == null) return;

    emit(current.copyWith(actionLoading: true));
    try {
      final updated = await _saveInternalNote(selectedId, note);
      _emitUpdated(current, updated, 'Internal note saved');
    } catch (error) {
      emit(
        current.copyWith(actionLoading: false, actionMessage: error.toString()),
      );
    }
  }

  Future<void> markCustomerContacted() async {
    final current = state;
    if (current is! TicketsLoaded) return;
    final selectedId = current.selectedTicketId;
    if (selectedId == null) return;

    emit(current.copyWith(actionLoading: true));
    try {
      final updated = await _markCustomerContacted(selectedId);
      _emitUpdated(current, updated, 'Marked as contacted');
    } catch (error) {
      emit(
        current.copyWith(actionLoading: false, actionMessage: error.toString()),
      );
    }
  }

  Future<void> closeTicket() async {
    final current = state;
    if (current is! TicketsLoaded) return;
    final selectedId = current.selectedTicketId;
    if (selectedId == null) return;

    emit(current.copyWith(actionLoading: true));
    try {
      final updated = await _closeTicket(selectedId);
      _emitUpdated(current, updated, 'Ticket closed');
    } catch (error) {
      emit(
        current.copyWith(actionLoading: false, actionMessage: error.toString()),
      );
    }
  }

  void _emitUpdated(
    TicketsLoaded current,
    SupportTicket updated,
    String successMsg,
  ) {
    final updatedList = current.tickets
        .map((t) => t.id == updated.id ? updated : t)
        .toList();
    emit(
      current.copyWith(
        tickets: updatedList,
        actionLoading: false,
        actionMessage: successMsg,
      ),
    );
  }

  void clearActionMessage() {
    if (state is TicketsLoaded) {
      emit((state as TicketsLoaded).copyWith(actionMessage: null));
    }
  }
}
