import '../../domain/entities/incident_report.dart';
import '../../domain/repositories/incident_repository.dart';
import '../datasources/incident_datasource.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  const IncidentRepositoryImpl(this._dataSource);

  final IncidentDataSource _dataSource;

  @override
  Future<IncidentReport> reportIncident(IncidentReport report) async {
    return (await _dataSource.reportIncident(report)).toEntity();
  }
}
