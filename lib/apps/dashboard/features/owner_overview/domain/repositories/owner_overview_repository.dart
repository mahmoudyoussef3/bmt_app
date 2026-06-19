import '../entities/owner_overview.dart';

abstract class OwnerOverviewRepository {
  Future<OwnerOverview> getOverview();
}
