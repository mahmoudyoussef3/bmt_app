import '../entities/office_profile.dart';

abstract class OfficeProfileRepository {
  Future<OfficeProfile> getProfile();
  Future<OfficeProfile> updateProfile(OfficeProfileEdit edit);
}
