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
}
