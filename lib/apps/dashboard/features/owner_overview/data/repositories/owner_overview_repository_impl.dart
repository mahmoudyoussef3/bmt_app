import '../../domain/entities/owner_overview.dart';
import '../../domain/repositories/owner_overview_repository.dart';
import '../datasources/owner_overview_datasource.dart';

class OwnerOverviewRepositoryImpl implements OwnerOverviewRepository {
  final OwnerOverviewDatasource _datasource;

  const OwnerOverviewRepositoryImpl(this._datasource);

  @override
  Future<OwnerOverview> getOverview() async {
    try {
      return await _datasource.getOverview();
    } catch (_) {
      throw Exception('تعذر تحميل ملخص الإيرادات');
    }
  }
}
