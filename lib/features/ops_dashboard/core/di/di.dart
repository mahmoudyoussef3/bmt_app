import 'package:get_it/get_it.dart';
import '../data/repositories/mock_support_ticket_repository.dart';
import '../domain/repositories/support_ticket_repository.dart';
import 'network/websocket_service.dart';
import 'audit/audit_service.dart';

final GetIt di = GetIt.instance;

void registerOpsCenterDependencies() {
  // Core
  di.registerLazySingleton(() => WebSocketService());
  di.registerLazySingleton(() => AuditService());

  // Repositories
  di.registerLazySingleton<SupportTicketRepository>(
    () => MockSupportTicketRepository(),
  );
}
