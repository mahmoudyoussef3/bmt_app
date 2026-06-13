import '../models/home_data_model.dart';

abstract class HomeDatasource {
  Future<HomeDataModel> getHomeData();
}
