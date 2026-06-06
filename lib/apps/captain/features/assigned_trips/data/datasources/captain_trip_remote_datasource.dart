import '../../domain/entities/assigned_trip.dart';
import '../models/assigned_trip_model.dart';

class CaptainTripRemoteDataSource {
  const CaptainTripRemoteDataSource();

  Future<List<AssignedTripModel>> getAssignedTrips() async {
    final now = DateTime.now();
    return [
      AssignedTripModel(
        id: 't1',
        route: 'Banha → Smart Village',
        vehicleNumber: 'MT-2847',
        plateNumber: 'ABC-1234',
        departureTime: DateTime(now.year, now.month, now.day, 8, 30),
        expectedArrivalTime: DateTime(now.year, now.month, now.day, 9, 15),
        stops: const [
          'Banha Station',
          'Banha Center',
          'Banha Downtown',
          'Smart Village',
        ],
        passengerCount: 9,
        boardedCount: 0,
        status: AssignedTripStatus.scheduled,
      ),
      AssignedTripModel(
        id: 't2',
        route: 'Banha → Nasr City',
        vehicleNumber: 'MT-2847',
        plateNumber: 'ABC-1234',
        departureTime: DateTime(now.year, now.month, now.day, 10),
        expectedArrivalTime: DateTime(now.year, now.month, now.day, 10, 50),
        stops: const ['Banha Station', 'Banha Downtown', 'Nasr City'],
        passengerCount: 5,
        boardedCount: 0,
        status: AssignedTripStatus.scheduled,
      ),
    ];
  }
}
