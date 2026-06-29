import '../entities/complaint.dart';
import '../repositories/tickets_repository.dart';

class AssignAgentUseCase {
  final TicketsRepository _repository;
  const AssignAgentUseCase(this._repository);

  Future<SupportTicket> call(
    String ticketId,
    String agentId,
    String agentName,
  ) {
    return _repository.assignAgent(ticketId, agentId, agentName);
  }
}

class GetAgentsUseCase {
  final TicketsRepository _repository;
  const GetAgentsUseCase(this._repository);

  Future<List<Map<String, dynamic>>> call() {
    return _repository.getAgents();
  }
}
