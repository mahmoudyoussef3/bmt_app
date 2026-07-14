import '../../domain/entities/client_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._datasource);

  final ProfileDatasource _datasource;

  @override
  Future<ClientProfile> getProfile() async {
    final model = await _datasource.getProfile();
    return model.toEntity();
  }

  @override
  Future<ClientProfile> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final model = await _datasource.updateProfile(
      name: name,
      email: email,
      phone: phone,
    );
    return model.toEntity();
  }
}
