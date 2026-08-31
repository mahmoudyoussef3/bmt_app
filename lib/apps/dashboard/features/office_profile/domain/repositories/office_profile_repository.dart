import 'dart:typed_data';

import '../entities/office_profile.dart';

abstract class OfficeProfileRepository {
  Future<OfficeProfile> getProfile();
  Future<OfficeProfile> updateProfile(OfficeProfileEdit edit);

  /// Stores a picked image as the office's logo and returns its public URL.
  Future<String> uploadLogo({
    required Uint8List bytes,
    required String fileName,
  });

  /// Issues a new captain join code and returns the office as it now stands.
  ///
  /// Returns the whole profile rather than the code alone so nothing on the
  /// client reconstructs a platform-owned field: the new code and its rotation
  /// time come back from the database that minted them.
  Future<OfficeProfile> rotateJoinCode();
}
