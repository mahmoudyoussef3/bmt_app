import '../../domain/entities/passenger.dart';

sealed class PassengerManifestState {
  const PassengerManifestState();
}

class PassengerManifestLoading extends PassengerManifestState {
  const PassengerManifestLoading();
}

class PassengerManifestLoaded extends PassengerManifestState {
  const PassengerManifestLoaded(this.passengers);

  final List<Passenger> passengers;
}

class PassengerManifestError extends PassengerManifestState {
  const PassengerManifestError(this.message);

  final String message;
}

class PassengerManifestUpdateError extends PassengerManifestState {
  const PassengerManifestUpdateError(this.passengers, this.message);

  final List<Passenger> passengers;
  final String message;
}
