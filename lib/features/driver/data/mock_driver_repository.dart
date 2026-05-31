import 'package:bmt_app/features/driver/data/driver_repository.dart';
import 'package:bmt_app/features/driver/domain/repositories/driver_repository_interface.dart';

/// Mock wrapper around the existing `DriverRepository` demo implementation.
/// This is intentionally a thin adapter so we can register a mock implementation
/// with DI without changing the existing `DriverRepository` behaviour.
import 'package:bmt_app/features/driver/domain/models/driver_profile.dart';
import 'package:bmt_app/features/driver/domain/models/shift.dart';

class MockDriverRepository extends DriverRepository
    implements IDriverRepository {
  // In-memory profile and shifts for Phase 1
  DriverProfile _profile = DriverProfile(
    id: 'd1',
    name: 'Demo Driver',
    phone: '+20 100 000 000',
    licenseNumber: 'DL-123456',
    licenseExpiry: DateTime.now().add(const Duration(days: 365)),
    vehicleId: 'v1',
  );

  final List<ShiftRecord> _shifts = [];

  @override
  Future<DriverProfile> getDriverProfile() async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _profile;
  }

  @override
  Future<void> updateDriverProfile(DriverProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 80));
    _profile = profile;
  }

  @override
  Future<void> saveShift(ShiftRecord shift) async {
    await Future.delayed(const Duration(milliseconds: 80));
    _shifts.add(shift);
  }

  @override
  List<ShiftRecord> getShifts() => List.unmodifiable(_shifts);
}
