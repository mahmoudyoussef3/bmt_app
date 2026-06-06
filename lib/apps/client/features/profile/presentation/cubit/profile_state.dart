import '../../domain/entities/client_profile.dart';

sealed class ProfileState {
  const ProfileState();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.data);

  final ClientProfileData data;
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;
}
