import 'dart:typed_data';

import '../../domain/entities/office_profile.dart';
import '../../domain/repositories/office_profile_repository.dart';
import '../datasources/office_profile_datasource.dart';

class OfficeProfileRepositoryImpl implements OfficeProfileRepository {
  const OfficeProfileRepositoryImpl(this._datasource);

  final OfficeProfileDatasource _datasource;

  @override
  Future<OfficeProfile> getProfile() => _datasource.getProfile();

  @override
  Future<OfficeProfile> updateProfile(OfficeProfileEdit edit) =>
      _datasource.updateProfile(edit);

  @override
  Future<String> uploadLogo({
    required Uint8List bytes,
    required String fileName,
  }) => _datasource.uploadLogo(bytes: bytes, fileName: fileName);
}
