import '../entities/client_profile.dart';

abstract class ProfileRepository {
  Future<ClientProfileData> getProfileData();
}
