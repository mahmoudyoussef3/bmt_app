import '../../domain/entities/client_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/mock_profile_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._datasource);

  final MockProfileDatasource _datasource;

  @override
  Future<ClientProfileData> getProfileData() async {
    final data = await _datasource.getProfileData();
    return data.toEntity();
  }
}
