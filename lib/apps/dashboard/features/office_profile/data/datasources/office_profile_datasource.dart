import 'dart:typed_data';

import '../../domain/entities/office_profile.dart';

abstract class OfficeProfileDatasource {
  /// Reads the signed-in operator's own office.
  Future<OfficeProfile> getProfile();

  /// Writes the marketplace-facing fields and returns the stored row.
  Future<OfficeProfile> updateProfile(OfficeProfileEdit edit);

  /// Stores [bytes] as the office's logo and returns its public URL.
  ///
  /// Uploading does not save the profile — the returned URL goes into the form
  /// and is written with the rest of the fields, so a picked file the operator
  /// then abandons never becomes the live logo.
  Future<String> uploadLogo({
    required Uint8List bytes,
    required String fileName,
  });

  /// Rotates the captain join code and returns the office as it now stands.
  Future<OfficeProfile> rotateJoinCode();
}
