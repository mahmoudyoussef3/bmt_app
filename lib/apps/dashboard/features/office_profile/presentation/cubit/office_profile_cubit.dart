import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/office_profile.dart';
import '../../domain/usecases/office_profile_usecases.dart';
import 'office_profile_state.dart';

class OfficeProfileCubit extends Cubit<OfficeProfileState> {
  OfficeProfileCubit({
    required GetOfficeProfileUseCase getProfile,
    required UpdateOfficeProfileUseCase updateProfile,
    required UploadOfficeLogoUseCase uploadLogo,
  }) : _getProfile = getProfile,
       _updateProfile = updateProfile,
       _uploadLogo = uploadLogo,
       super(const OfficeProfileInitial());

  final GetOfficeProfileUseCase _getProfile;
  final UpdateOfficeProfileUseCase _updateProfile;
  final UploadOfficeLogoUseCase _uploadLogo;

  Future<void> load() async {
    emit(const OfficeProfileLoading());
    try {
      emit(OfficeProfileLoaded(await _getProfile()));
    } catch (error) {
      emit(OfficeProfileError(_message(error)));
    }
  }

  Future<void> save(OfficeProfileEdit edit) async {
    final current = _profile();
    if (current == null) return;

    emit(OfficeProfileLoaded(current, isSaving: true));
    try {
      final updated = await _updateProfile(edit);
      emit(OfficeProfileActionSuccess('تم حفظ بيانات المكتب', updated));
      emit(OfficeProfileLoaded(updated));
    } catch (error) {
      
      emit(OfficeProfileActionFailure(_message(error), current));
      emit(OfficeProfileLoaded(current));
    }
  }

  /// Uploads a picked image and returns its public URL, or null if it failed.
  ///
  /// Returning the URL rather than storing it: the logo is one field in a form
  /// the operator may still be editing, so the upload hands the URL back to the
  /// form and `offices.logo_url` changes only when they save. A failure is
  /// reported as an action failure — a snack bar over the form — because the
  /// screen still has its data and their edits.
  Future<String?> uploadLogo({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final current = _profile();
    if (current == null) return null;

    emit(OfficeProfileLoaded(current, isUploadingLogo: true));
    try {
      final url = await _uploadLogo(bytes: bytes, fileName: fileName);
      emit(OfficeProfileLoaded(current));
      return url;
    } catch (error) {
      emit(OfficeProfileActionFailure(_message(error), current));
      emit(OfficeProfileLoaded(current));
      return null;
    }
  }

  OfficeProfile? _profile() {
    final current = state;
    return switch (current) {
      OfficeProfileLoaded() => current.profile,
      OfficeProfileActionSuccess() => current.profile,
      OfficeProfileActionFailure() => current.profile,
      _ => null,
    };
  }

  String _message(Object error) =>
      error.toString().replaceAll('Exception: ', '');
}
