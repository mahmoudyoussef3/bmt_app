import '../../domain/entities/office_route.dart';
import '../../domain/entities/office_summary.dart';
import '../../domain/repositories/offices_repository.dart';
import '../datasources/offices_datasource.dart';

class OfficesRepositoryImpl implements OfficesRepository {
  const OfficesRepositoryImpl(this._datasource);

  final OfficesDatasource _datasource;

  @override
  Future<List<OfficeSummary>> getOffices() => _datasource.fetchOffices();

  @override
  Future<List<OfficeRoute>> getOfficeRoutes(String officeId) =>
      _datasource.fetchOfficeRoutes(officeId);
}
