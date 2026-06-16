import '../../domain/entities/complaint.dart';
import '../../domain/repositories/tickets_repository.dart';
import '../datasources/supabase_tickets_datasource.dart';

class TicketsRepositoryImpl implements TicketsRepository {
  final SupabaseTicketsDatasource _datasource;

  const TicketsRepositoryImpl(this._datasource);

  @override
  Future<List<SupportTicket>> getTickets() async {
    try {
      return await _datasource.getTickets();
    } catch (e, stack) {
      print('Error loading tickets: $e');
      print(stack);
      throw Exception('Failed to load tickets: $e');
    }
  }

  @override
  Future<SupportTicket> updateTicketStatus(String id, TicketStatus status) async {
    try {
      return await _datasource.updateTicketStatus(id, status);
    } catch (_) {
      throw Exception('Failed to update ticket status');
    }
  }

  @override
  Future<SupportTicket> saveInternalNote(String id, String note) async {
    try {
      return await _datasource.saveInternalNote(id, note);
    } catch (_) {
      throw Exception('Failed to save internal note');
    }
  }

  @override
  Future<SupportTicket> markCustomerContacted(String id) async {
    try {
      return await _datasource.markCustomerContacted(id);
    } catch (_) {
      throw Exception('Failed to mark customer as contacted');
    }
  }

  @override
  Future<SupportTicket> closeTicket(String id) async {
    try {
      return await _datasource.closeTicket(id);
    } catch (_) {
      throw Exception('Failed to close ticket');
    }
  }

  @override
  Future<List<SupportAttachment>> getTicketAttachments(String ticketId) async {
    try {
      return await _datasource.getTicketAttachments(ticketId);
    } catch (_) {
      throw Exception('Failed to get ticket attachments');
    }
  }

  @override
  Future<SupportTicket> assignAgent(
    String ticketId,
    String agentId,
    String agentName,
  ) async {
    try {
      return await _datasource.assignAgent(ticketId, agentId, agentName);
    } catch (_) {
      throw Exception('Failed to assign agent');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAgents() async {
    try {
      return await _datasource.getAgents();
    } catch (_) {
      throw Exception('Failed to load agents');
    }
  }
}
