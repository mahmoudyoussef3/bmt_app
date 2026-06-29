import '../../domain/entities/driver_profile.dart';

sealed class DriverProfileState {
  const DriverProfileState();
}

class DriverProfileLoading extends DriverProfileState {
  const DriverProfileLoading();
}

class DriverProfileLoaded extends DriverProfileState {
  const DriverProfileLoaded(this.profile);
  final DriverProfile profile;
}

class DriverProfileError extends DriverProfileState {
  const DriverProfileError(this.message);
  final String message;
}
