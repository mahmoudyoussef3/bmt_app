import '../../domain/models/kpi.dart';
import '../../domain/repositories/kpi_repository.dart';

class MockKpiRepository implements KpiRepository {
  @override
  Future<List<Kpi>> fetchKpis() async {
    // Simulated KPI values; in production these would be fetched from services
    await Future.delayed(const Duration(milliseconds: 120));
    return [
      Kpi(id: 'active_trips', label: 'Active Trips', value: '24'),
      Kpi(id: 'delayed_trips', label: 'Delayed Trips', value: '3'),
      Kpi(id: 'completed_today', label: 'Completed Today', value: '412'),
      Kpi(id: 'cancelled_bookings', label: 'Cancelled Bookings', value: '7'),
      Kpi(id: 'active_drivers', label: 'Active Drivers', value: '120'),
      Kpi(id: 'revenue_today', label: 'Revenue Today', value: '12,345'),
    ];
  }
}
