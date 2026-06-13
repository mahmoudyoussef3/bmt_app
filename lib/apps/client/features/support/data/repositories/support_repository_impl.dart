import '../../domain/entities/support_data.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_datasource.dart';

class SupportRepositoryImpl implements SupportRepository {
  const SupportRepositoryImpl(this._datasource);

  final SupportDatasource _datasource;

  @override
  Future<SupportData> getSupportData() async {
    final categories = await _datasource.getCategories();
    final tickets = await _datasource.getTickets();

    return SupportData(
      categories: categories,
      tickets: tickets.map((t) => t.toEntity()).toList(),
    );
  }

  @override
  Future<SupportTicket> createTicket(Map<String, dynamic> data) async {
    final ticket = await _datasource.createTicket(data);
    return ticket.toEntity();
  }

  @override
  Future<SupportTicket> addMessage(String ticketId, Map<String, dynamic> message) async {
    final ticket = await _datasource.addMessage(ticketId, message);
    return ticket.toEntity();
  }
}
