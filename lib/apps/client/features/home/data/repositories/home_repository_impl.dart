import '../../domain/entities/home_data.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/mock_home_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._datasource);

  final MockHomeDatasource _datasource;

  @override
  Future<HomeData> getHomeData() async {
    final model = await _datasource.getHomeData();
    return model.toEntity();
  }
}
