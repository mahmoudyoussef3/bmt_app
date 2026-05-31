import 'package:get_it/get_it.dart';
import '../data/repositories/mock_support_ticket_repository.dart';
import '../data/repositories/mock_kpi_repository.dart';
import '../data/repositories/mock_trip_stream_repository.dart';
import '../data/repositories/mock_driver_stream_repository.dart';
import '../domain/repositories/support_ticket_repository.dart';
import '../domain/repositories/kpi_repository.dart';
import '../domain/repositories/trip_stream_repository.dart';
import '../domain/repositories/driver_stream_repository.dart';
import '../core/eventbus/live_event_bus.dart';
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
  di.registerLazySingleton<KpiRepository>(() => MockKpiRepository());
  di.registerLazySingleton<TripStreamRepository>(
    () => MockTripStreamRepository(ws: di<WebSocketService>()),
  );
  di.registerLazySingleton<DriverStreamRepository>(
    () => MockDriverStreamRepository(),
  );
  di.registerLazySingleton<LiveEventBus>(
    () => LiveEventBus(di<WebSocketService>()),
  );
}
