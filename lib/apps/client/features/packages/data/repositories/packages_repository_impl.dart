import '../../domain/entities/my_subscription.dart';
import '../../domain/entities/package_plan.dart';
import '../../domain/repositories/packages_repository.dart';
import '../datasources/packages_datasource.dart';
import '../mappers/my_subscription_mapper.dart';
import '../mappers/package_plan_mapper.dart';

class PackagesRepositoryImpl implements PackagesRepository {
  const PackagesRepositoryImpl(this._datasource);

  final PackagesDatasource _datasource;

  @override
  Future<List<PackagePlan>> getPackages() async {
    final models = await _datasource.getPackages();
    return models.toEntities();
  }

  @override
  Future<MySubscription?> getMySubscription() async {
    final row = await _datasource.getMySubscription();
    return MySubscriptionMapper.fromRow(row);
  }
}
