import '../../domain/entities/office_profile.dart';

abstract class OfficeProfileDatasource {
  /// Reads the signed-in operator's own office.
  Future<OfficeProfile> getProfile();

  /// Writes the marketplace-facing fields and returns the stored row.
  Future<OfficeProfile> updateProfile(OfficeProfileEdit edit);
}
