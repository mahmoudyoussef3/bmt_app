import '../../domain/entities/client_profile.dart';

sealed class ProfileState {
  const ProfileState();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.data, {this.refreshFailure});

  final ClientProfileData data;

  /// Set when a pull-to-refresh failed while this data was on screen —
  /// the UI keeps the content and surfaces the failure non-destructively.
  final String? refreshFailure;
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;
}
