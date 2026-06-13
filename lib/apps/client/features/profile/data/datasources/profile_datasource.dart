import '../models/client_profile_model.dart';

abstract class ProfileDatasource {
  Future<ClientProfileDataModel> getProfileData();
}
