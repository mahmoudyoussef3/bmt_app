import '../../domain/entities/passenger.dart';
import '../models/passenger_model.dart';

class PassengerManifestDataSource {
  const PassengerManifestDataSource();

  Future<List<PassengerModel>> getTripPassengers(String tripId) async {
    final prefix = tripId == 't2' ? 'q' : 'p';
    final count = tripId == 't2' ? 5 : 9;
    final destination = tripId == 't2' ? 'Nasr City' : 'Smart Village';
    final pickup = tripId == 't2' ? 'Banha Downtown' : 'Banha Center';
    return List.generate(
      count,
      (index) => PassengerModel(
        id: '$prefix${index + 1}',
        name: tripId == 't2'
            ? 'Passenger Q${index + 1}'
            : 'Passenger ${index + 1}',
        seat: '${tripId == 't2' ? index + 11 : index + 1}',
        pickupPoint: index.isEven ? pickup : 'Banha Station',
        destination: destination,
        pickupTime: tripId == 't2'
            ? '9:${50 + index * 5}'
            : '8:${30 + (index % 3) * 5}',
        phone: '+20 100 000 ${100 + index}',
        status: PassengerBoardingStatus.pending,
      ),
    );
  }
}
