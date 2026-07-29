import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_profile_data_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._getProfile, this._updateProfile)
    : super(const ProfileLoading());

  final GetProfileDataUseCase _getProfile;
  final UpdateProfileUseCase _updateProfile;

  /// Loads the profile. When content is already on screen (pull-to-refresh)
  /// the loaded state is kept rather than flashing the skeleton, and a refresh
  /// failure keeps that content instead of replacing it with a full-page error.
  Future<void> load() async {
    final previous = state;
    if (previous is! ProfileLoaded) emit(const ProfileLoading());

    try {
      final profile = await _getProfile();
      emit(ProfileLoaded(profile));
    } on ProfileUnauthenticatedException {
      emit(const ProfileUnauthenticated());
    } catch (error) {
      if (previous is ProfileLoaded) {
        emit(previous.copyWith(refreshFailed: true));
      } else {
        emit(ProfileError(_messageFor(error)));
      }
    }
  }

  /// Saves the rider's contact details. Field-level rejections come back as
  /// [ProfileFieldError]s so the form can point at the offending input; only a
  /// genuine failure (offline, phone already taken) becomes a [saveError].
  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final current = state;
    if (current is! ProfileLoaded || current.isSaving) return;

    emit(
      current.copyWith(
        editStatus: ProfileEditStatus.saving,
        fieldErrors: const {},
        clearSaveError: true,
      ),
    );

    try {
      final saved = await _updateProfile(
        name: name,
        email: email,
        phone: phone,
      );
      emit(
        current.copyWith(
          profile: saved,
          editStatus: ProfileEditStatus.success,
          refreshFailed: false,
        ),
      );
    } on ProfileValidationException catch (error) {
      emit(
        current.copyWith(
          editStatus: ProfileEditStatus.failure,
          fieldErrors: error.errors,
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          editStatus: ProfileEditStatus.failure,
          saveError: _messageFor(error),
        ),
      );
    }
  }

  /// Returns the form to a neutral state once the UI has shown the outcome, so
  /// reopening the edit sheet never starts on a stale error or success.
  void resetEditStatus() {
    final current = state;
    if (current is! ProfileLoaded) return;
    emit(
      current.copyWith(
        editStatus: ProfileEditStatus.idle,
        fieldErrors: const {},
        clearSaveError: true,
      ),
    );
  }

  /// Marks the refresh banner as seen.
  void dismissRefreshFailure() {
    final current = state;
    if (current is! ProfileLoaded || !current.refreshFailed) return;
    emit(current.copyWith(refreshFailed: false));
  }

  String _messageFor(Object error) =>
      error.toString().replaceAll('Exception: ', '');
}
