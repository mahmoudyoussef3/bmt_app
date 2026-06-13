import '../../domain/entities/package_plan.dart';
import '../../domain/repositories/packages_repository.dart';
import '../datasources/packages_datasource.dart';

class PackagesRepositoryImpl implements PackagesRepository {
  const PackagesRepositoryImpl(this._datasource);

  final PackagesDatasource _datasource;

  @override
  Future<PackageSelectionData> getSelectionData() async {
    final data = await _datasource.getSelectionData();
    return data.toEntity();
  }
}
