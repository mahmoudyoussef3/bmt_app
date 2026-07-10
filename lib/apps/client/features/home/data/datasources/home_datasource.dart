import '../models/home_data_model.dart';

abstract class HomeDatasource {
  Future<HomeDataModel> getHomeData();

  /// Emits whenever a trip that could affect Home's listings changes
  /// (e.g. a trip completes and should stop appearing as bookable).
  Stream<void> watchHomeChanges();
}
