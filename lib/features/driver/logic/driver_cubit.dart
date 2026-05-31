import 'package:flutter/foundation.dart';
import 'package:bmt_app/features/driver/domain/repositories/driver_repository_interface.dart';
import 'package:bmt_app/features/driver/domain/models/trip.dart';
import 'package:bmt_app/features/driver/domain/models/passenger.dart';
import 'package:bmt_app/features/driver/domain/models/driver_notification.dart';
import 'package:bmt_app/features/driver/domain/models/incident.dart';
import 'package:bmt_app/features/driver/domain/models/inspection_report.dart';
import 'package:bmt_app/features/driver/domain/models/driver_profile.dart';
import 'package:bmt_app/features/driver/domain/models/shift.dart';

class DriverCubit extends ChangeNotifier {
  final IDriverRepository _repo;

  List<Trip> _trips = [];
  List<Trip> get trips => _trips;

  Trip? _selectedTrip;
  Trip? get selectedTrip => _selectedTrip;

  List<DriverNotification> _notifications = [];
  List<DriverNotification> get notifications => _notifications;

  bool _sharingLocation = false;
  bool get sharingLocation => _sharingLocation;

  DriverCubit(this._repo);

  Future<void> loadTodaysTrips() async {
    _trips = _repo.getTodaysTrips();
    notifyListeners();
  }

  Future<void> selectTrip(String id) async {
    _selectedTrip = _trips.isEmpty
        ? null
        : _trips.firstWhere((t) => t.id == id, orElse: () => _trips.first);
    notifyListeners();
  }

  Future<void> startTrip(String id) async {
    final t = _trips.firstWhere((x) => x.id == id);
    t.status = TripStatus.inProgress;
    notifyListeners();
  }

  Future<void> completeTrip(String id) async {
    final t = _trips.firstWhere((x) => x.id == id);
    t.status = TripStatus.completed;
    notifyListeners();
  }

  Future<void> updatePassengerStatus(
    String tripId,
    String passengerId,
    PassengerStatus status,
  ) async {
    await _repo.updatePassengerStatus(tripId, passengerId, status);
    final t = _trips.firstWhere((x) => x.id == tripId);
    final p = t.passengers.firstWhere((p) => p.id == passengerId);
    p.status = status;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _notifications = _repo.getNotifications();
    notifyListeners();
  }

  Future<void> reportIncident(Incident incident) async {
    await _repo.reportIncident(incident);
    notifyListeners();
  }

  Future<InspectionReport> submitInspection(Map<String, bool> checks) async {
    final r = await _repo.submitInspection(checks);
    notifyListeners();
    return r;
  }

  // Profile
  DriverProfile? _profile;
  DriverProfile? get profile => _profile;

  Future<void> loadProfile() async {
    _profile = await _repo.getDriverProfile();
    notifyListeners();
  }

  Future<void> updateProfile(DriverProfile p) async {
    await _repo.updateDriverProfile(p);
    _profile = p;
    notifyListeners();
  }

  // Shift / Attendance
  ShiftRecord? _currentShift;
  ShiftRecord? get currentShift => _currentShift;

  final List<ShiftRecord> _shifts = [];
  List<ShiftRecord> get shifts => List.unmodifiable(_shifts);

  Future<void> startShift() async {
    final s = ShiftRecord(
      id: 's-${DateTime.now().millisecondsSinceEpoch}',
      start: DateTime.now(),
    );
    _currentShift = s;
    notifyListeners();
  }

  Future<void> endShift() async {
    if (_currentShift == null) return;
    _currentShift!.end = DateTime.now();
    await _repo.saveShift(_currentShift!);
    _shifts.add(_currentShift!);
    _currentShift = null;
    notifyListeners();
  }

  void toggleShareLocation() {
    _sharingLocation = !_sharingLocation;
    notifyListeners();
  }
}
