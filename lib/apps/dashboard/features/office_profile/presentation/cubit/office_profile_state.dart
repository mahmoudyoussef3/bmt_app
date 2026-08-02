import '../../domain/entities/office_profile.dart';

sealed class OfficeProfileState {
  const OfficeProfileState();
}

class OfficeProfileInitial extends OfficeProfileState {
  const OfficeProfileInitial();
}

class OfficeProfileLoading extends OfficeProfileState {
  const OfficeProfileLoading();
}

class OfficeProfileError extends OfficeProfileState {
  const OfficeProfileError(this.message);
  final String message;
}

class OfficeProfileLoaded extends OfficeProfileState {
  const OfficeProfileLoaded(
    this.profile, {
    this.isSaving = false,
    this.isUploadingLogo = false,
  });
  final OfficeProfile profile;
  final bool isSaving;

  /// A logo file is being uploaded to storage. Tracked apart from [isSaving]
  /// because it is not a save: the upload only produces a URL for the form, and
  /// the profile is unchanged until the operator presses save.
  final bool isUploadingLogo;

  OfficeProfileLoaded copyWith({
    OfficeProfile? profile,
    bool? isSaving,
    bool? isUploadingLogo,
  }) => OfficeProfileLoaded(
    profile ?? this.profile,
    isSaving: isSaving ?? this.isSaving,
    isUploadingLogo: isUploadingLogo ?? this.isUploadingLogo,
  );
}

/// Emitted for one frame after a successful write so the screen can show a
/// snack bar, then immediately followed by [OfficeProfileLoaded] — same shape
/// the referrals module uses, so listeners behave identically across modules.
class OfficeProfileActionSuccess extends OfficeProfileState {
  const OfficeProfileActionSuccess(this.message, this.profile);
  final String message;
  final OfficeProfile profile;
}

/// A failed write, carrying the last good [profile] alongside the message.
///
/// Distinct from [OfficeProfileError], which means "the screen has no data".
/// A rejected save still has data — and, more importantly, still has whatever
/// the operator typed — so it must not take the form off screen.
class OfficeProfileActionFailure extends OfficeProfileState {
  const OfficeProfileActionFailure(this.message, this.profile);
  final String message;
  final OfficeProfile profile;
}
