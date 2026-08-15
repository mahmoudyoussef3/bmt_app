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
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_filter_memory.dart';

import 'tickets_state.dart';

/// The support queue's three filter axes as one remembered value.
///
/// Tickets keeps its filters as separate fields on the state rather than in a
/// value object like `BookingFilters`, so this record is what gets handed to
/// [DashboardFilterMemory] — enough to restore the operator's view, and
/// nothing else from the state comes with it.
typedef TicketFilterSnapshot = ({
  String search,
  TicketStatus? status,
  TicketPriority? priority,
});

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
      // Restores the triage the agent was working in — "الطلبات العاجلة
      // المفتوحة" — after they opened a ticket and came back. The toolbar
      // shows the selected chips, so the narrowed queue never looks whole.
      final remembered = DashboardFilterMemory.instance
          .read<TicketFilterSnapshot>(DashboardFilterIds.tickets);
      emit(
        TicketsLoaded(
          tickets: results[0] as List<SupportTicket>,
          agents: results[1] as List<Map<String, dynamic>>,
          searchQuery: remembered?.search ?? '',
          filterStatus: remembered?.status,
          filterPriority: remembered?.priority,
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
        'تم إسناد التذكرة إلى $agentName',
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
    _remember(
      current.copyWith(filterStatus: status, clearFilterStatus: status == null),
    );
  }

  void setFilterPriority(TicketPriority? priority) {
    final current = state;
    if (current is! TicketsLoaded) return;
    _remember(
      current.copyWith(
        filterPriority: priority,
        clearFilterPriority: priority == null,
      ),
    );
  }

  void setSearchQuery(String query) {
    final current = state;
    if (current is! TicketsLoaded) return;
    _remember(current.copyWith(searchQuery: query));
  }

  /// Emits [next] and files its filters away for the operator's next visit.
  /// Every filter setter goes through here so none can be added later that
  /// silently forgets.
  void _remember(TicketsLoaded next) {
    DashboardFilterMemory.instance.write(DashboardFilterIds.tickets, (
      search: next.searchQuery,
      status: next.filterStatus,
      priority: next.filterPriority,
    ));
    emit(next);
  }

  /// Drops every filter at once, including the search text — what the empty
  /// state's "مسح الفلاتر" offers when a filtered queue comes back with nothing.
  void clearFilters() {
    final current = state;
    if (current is! TicketsLoaded) return;
    // Forget rather than remember an empty snapshot, so "cleared" survives
    // navigation the same way a selection does.
    DashboardFilterMemory.instance.forget(DashboardFilterIds.tickets);
    emit(
      current.copyWith(
        searchQuery: '',
        clearFilterStatus: true,
        clearFilterPriority: true,
      ),
    );
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
        'تم تحديث حالة التذكرة إلى «${status.label}»',
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
      _emitUpdated(current, updated, 'تم حفظ الملاحظة الداخلية');
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
      _emitUpdated(current, updated, 'تم تسجيل التواصل مع العميل');
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
      _emitUpdated(current, updated, 'تم إغلاق التذكرة');
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
