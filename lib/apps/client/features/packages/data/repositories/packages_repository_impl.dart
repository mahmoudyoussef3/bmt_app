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
  Future<List<PackagePlan>> getOfficePackages(String officeId) async {
    final models = await _datasource.getPackages(officeId: officeId);
    return _marketplaceReady(models.toEntities());
  }

  @override
  Future<List<PackagePlan>> getTripPackages({
    required String officeId,
    required Set<String> packageIds,
  }) async {
    final models = await _datasource.getTripPackages(
      officeId: officeId,
      packageIds: packageIds,
    );
    return _marketplaceReady(models.toEntities());
  }

  /// Drops any package whose seller did not resolve through `public_offices`.
  /// The server filter (embedding a listed-office view) is the fast path; this
  /// predicate is the guarantee — a rider never sees a package they cannot
  /// attribute to an office, mirroring how the trip surfaces re-check status.
  List<PackagePlan> _marketplaceReady(List<PackagePlan> packages) =>
      packages.where((package) => package.hasOffice).toList(growable: false);

  @override
  Future<MySubscription?> getMySubscription() async {
    final row = await _datasource.getMySubscription();
    return MySubscriptionMapper.fromRow(row);
  }
}
