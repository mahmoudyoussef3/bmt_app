import '../models/client_profile_model.dart';

abstract class ProfileDatasource {
  Future<ClientProfileModel> getProfile();

  Future<ClientProfileModel> updateProfile({
    required String name,
    required String email,
    required String phone,
  });
}
