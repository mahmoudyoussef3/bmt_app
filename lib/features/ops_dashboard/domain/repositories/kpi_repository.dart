import '../models/kpi.dart';

abstract class KpiRepository {
  /// Returns a list of KPIs for the dashboard home.
  Future<List<Kpi>> fetchKpis();
}
