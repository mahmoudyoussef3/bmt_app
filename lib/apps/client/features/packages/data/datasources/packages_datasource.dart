import '../models/package_plan_model.dart';

abstract class PackagesDatasource {
  Future<PackageSelectionDataModel> getSelectionData();
}
