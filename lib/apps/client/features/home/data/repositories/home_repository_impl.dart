import '../../domain/entities/home_data.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._datasource);

  final HomeDatasource _datasource;

  @override
  Future<HomeData> getHomeData() async {
    final model = await _datasource.getHomeData();
    return model.toEntity();
  }
}
