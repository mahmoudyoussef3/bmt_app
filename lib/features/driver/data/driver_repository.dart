import 'package:bmt_app/features/driver/domain/models/trip.dart';
import 'package:bmt_app/features/driver/domain/models/vehicle.dart';
import 'package:bmt_app/features/driver/domain/models/passenger.dart';
import 'package:bmt_app/features/driver/domain/models/incident.dart';
import 'package:bmt_app/features/driver/domain/models/driver_notification.dart';
import 'package:bmt_app/features/driver/domain/models/inspection_report.dart';

class DriverRepository {
  // In-memory dummy data for the driver app demo
  final Vehicle _vehicle = Vehicle(
    id: 'v1',
    number: 'MT-2847',
    plate: 'ABC-1234',
    capacity: 12,
  );

  List<Trip> getTodaysTrips() {
    final now = DateTime.now();
    final trip1 = Trip(
      id: 't1',
      route: 'Banha → Smart Village',
      departure: DateTime(now.year, now.month, now.day, 8, 30),
      expectedArrival: DateTime(now.year, now.month, now.day, 9, 15),
      vehicle: _vehicle,
      stops: [
        'Banha Station',
        'Banha Center',
        'Banha Downtown',
        'Smart Village',
      ],
      passengers: List.generate(
        9,
        (i) => Passenger(
          id: 'p${i + 1}',
          name: 'Passenger ${i + 1}',
          seat: '${i + 1}',
          pickupPoint: i % 2 == 0 ? 'Banha Center' : 'Banha Station',
          destination: 'Smart Village',
          pickupTime: '8:${30 + (i % 3) * 5}',
          phone: '+20 100 000 ${100 + i}',
        ),
      ),
    );

    final trip2 = Trip(
      id: 't2',
      route: 'Banha → Nasr City',
      departure: DateTime(now.year, now.month, now.day, 10, 0),
      expectedArrival: DateTime(now.year, now.month, now.day, 10, 50),
      vehicle: _vehicle,
      stops: ['Banha Station', 'Banha Downtown', 'Nasr City'],
      passengers: List.generate(
        5,
        (i) => Passenger(
          id: 'q${i + 1}',
          name: 'Passenger Q${i + 1}',
          seat: '${i + 11}',
          pickupPoint: 'Banha Downtown',
          destination: 'Nasr City',
          pickupTime: '9:${50 + i * 5}',
          phone: '+20 100 010 ${200 + i}',
        ),
      ),
    );

    return [trip1, trip2];
  }

  Trip? getTripById(String id) {
    final trips = getTodaysTrips();
    for (final t in trips) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> updatePassengerStatus(
    String tripId,
    String passengerId,
    PassengerStatus status,
  ) async {
    // In a real repo this would call API and persist
    await Future.delayed(const Duration(milliseconds: 120));
  }

  Future<void> reportIncident(Incident incident) async {
    await Future.delayed(const Duration(milliseconds: 120));
  }

  List<DriverNotification> getNotifications() {
    return [
      DriverNotification(
        id: 'n1',
        title: 'New Booking',
        body: '1 new passenger assigned',
      ),
      DriverNotification(
        id: 'n2',
        title: 'Route Change',
        body: 'Route updated for trip t1',
        unread: true,
      ),
    ];
  }

  Future<InspectionReport> submitInspection(Map<String, bool> checks) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final passed = checks.values.every((v) => v);
    return InspectionReport(
      id: 'insp-${DateTime.now().millisecondsSinceEpoch}',
      checks: checks,
      passed: passed,
    );
  }
}
