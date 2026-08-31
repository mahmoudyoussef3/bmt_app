import 'dart:typed_data';

import '../entities/office_profile.dart';
import '../repositories/office_profile_repository.dart';

class GetOfficeProfileUseCase {
  const GetOfficeProfileUseCase(this._repository);
  final OfficeProfileRepository _repository;
  Future<OfficeProfile> call() => _repository.getProfile();
}

class UpdateOfficeProfileUseCase {
  const UpdateOfficeProfileUseCase(this._repository);
  final OfficeProfileRepository _repository;
  Future<OfficeProfile> call(OfficeProfileEdit edit) =>
      _repository.updateProfile(edit);
}

class UploadOfficeLogoUseCase {
  const UploadOfficeLogoUseCase(this._repository);
  final OfficeProfileRepository _repository;
  Future<String> call({required Uint8List bytes, required String fileName}) =>
      _repository.uploadLogo(bytes: bytes, fileName: fileName);
}

/// Invalidates the office's captain join code and issues a new one.
///
/// The old code stops working the moment this returns — which is the point:
/// an office whose code reached the wrong driver has no other way to take it
/// back. Pending captain requests already in the queue are unaffected; they
/// carry the office they were filed against, not the code.
class RotateOfficeJoinCodeUseCase {
  const RotateOfficeJoinCodeUseCase(this._repository);
  final OfficeProfileRepository _repository;
  Future<OfficeProfile> call() => _repository.rotateJoinCode();
}
