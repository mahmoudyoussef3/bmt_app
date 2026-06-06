import '../entities/package_plan.dart';

abstract class PackagesRepository {
  Future<PackageSelectionData> getSelectionData();
}
