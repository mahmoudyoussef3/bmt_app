import '../../domain/entities/client_profile.dart';
import '../../domain/usecases/update_profile_usecase.dart';

sealed class ProfileState {
  const ProfileState();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// The rider is browsing in guest mode: there is no session to load a profile
/// for. Distinct from [ProfileError] because retrying can never succeed here —
/// the only way out is signing in.
class ProfileUnauthenticated extends ProfileState {
  const ProfileUnauthenticated();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(
    this.profile, {
    this.refreshFailed = false,
    this.editStatus = ProfileEditStatus.idle,
    this.fieldErrors = const {},
    this.saveError,
  });

  final ClientProfile profile;

  /// A pull-to-refresh failed while this profile was on screen. The content
  /// stays put and the failure is surfaced non-destructively — replacing a
  /// working screen with a full-page error would be a downgrade.
  final bool refreshFailed;

  final ProfileEditStatus editStatus;

  /// Per-field rejections from [UpdateProfileUseCase]. Rendered next to the
  /// offending input, in the rider's language.
  final Map<ProfileField, ProfileFieldError> fieldErrors;

  /// A save that failed for a reason that is not about one field (offline, a
  /// phone number already taken by another account).
  final String? saveError;

  bool get isSaving => editStatus == ProfileEditStatus.saving;

  ProfileLoaded copyWith({
    ClientProfile? profile,
    bool? refreshFailed,
    ProfileEditStatus? editStatus,
    Map<ProfileField, ProfileFieldError>? fieldErrors,
    String? saveError,
    bool clearSaveError = false,
  }) {
    return ProfileLoaded(
      profile ?? this.profile,
      refreshFailed: refreshFailed ?? this.refreshFailed,
      editStatus: editStatus ?? this.editStatus,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      saveError: clearSaveError ? null : saveError ?? this.saveError,
    );
  }
}

enum ProfileEditStatus { idle, saving, success, failure }

class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;
}
