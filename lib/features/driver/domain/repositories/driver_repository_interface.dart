import 'package:bmt_app/features/driver/domain/models/trip.dart';
import 'package:bmt_app/features/driver/domain/models/passenger.dart';
import 'package:bmt_app/features/driver/domain/models/incident.dart';
import 'package:bmt_app/features/driver/domain/models/driver_notification.dart';
import 'package:bmt_app/features/driver/domain/models/inspection_report.dart';
import 'package:bmt_app/features/driver/domain/models/driver_profile.dart';
import 'package:bmt_app/features/driver/domain/models/shift.dart';

/// Repository interface for driver-related data operations.
/// Implementations should map to real HTTP / DB adapters.
abstract class IDriverRepository {
  List<Trip> getTodaysTrips();

  Trip? getTripById(String id);

  Future<void> updatePassengerStatus(
    String tripId,
    String passengerId,
    PassengerStatus status,
  );

  Future<void> reportIncident(Incident incident);

  List<DriverNotification> getNotifications();

  Future<InspectionReport> submitInspection(Map<String, bool> checks);

  // Profile operations
  Future<DriverProfile> getDriverProfile();
  Future<void> updateDriverProfile(DriverProfile profile);

  // Shift / attendance
  Future<void> saveShift(ShiftRecord shift);
  List<ShiftRecord> getShifts();
}
