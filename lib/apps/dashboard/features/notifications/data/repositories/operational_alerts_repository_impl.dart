import '../../domain/entities/operational_alert.dart';
import '../../domain/repositories/operational_alerts_repository.dart';
import '../datasources/supabase_operational_alerts_datasource.dart';

class OperationalAlertsRepositoryImpl implements OperationalAlertsRepository {
  const OperationalAlertsRepositoryImpl(this._datasource);

  final OperationalAlertsDatasource _datasource;

  @override
  Stream<List<OperationalAlert>> watchAlerts() => _datasource.watchAlerts().map(
    (rows) => rows.map((m) => m.toEntity()).toList(),
  );

  @override
  Stream<int> watchUnreadCount() => _datasource.watchUnreadCount();

  @override
  Future<void> markAsRead(String id) => _datasource.markAsRead(id);

  @override
  Future<void> markAllAsRead() => _datasource.markAllAsRead();
}
