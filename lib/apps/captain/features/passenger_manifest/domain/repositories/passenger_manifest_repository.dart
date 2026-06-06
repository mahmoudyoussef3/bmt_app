import '../entities/passenger.dart';

abstract class PassengerManifestRepository {
  Future<List<Passenger>> getTripPassengers(String tripId);
}
