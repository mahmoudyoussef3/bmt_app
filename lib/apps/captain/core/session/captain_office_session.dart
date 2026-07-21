import 'package:flutter/foundation.dart';

/// The signed-in captain's identity: who they are, and which office they work for.
///
/// The office is never chosen in the app and never passed through a route — it is
/// resolved from the captain's own `drivers` row at sign-in
/// (`resolve_captain_login` / `link_current_captain_driver` both return it). A captain
/// therefore cannot reach another office's data by manipulating anything client-side,
/// and RLS enforces the same boundary independently.
@immutable
class CaptainIdentity {
  const CaptainIdentity({
    required this.driverId,
    required this.officeId,
    this.officeName = '',
    this.fullName = '',
    this.phone = '',
    this.employeeCode = '',
  });

  final String driverId;
  final String officeId;
  final String officeName;
  final String fullName;
  final String phone;
  final String employeeCode;

  factory CaptainIdentity.fromRpc(Map<String, dynamic> row) {
    return CaptainIdentity(
      driverId: (row['driver_id'] as String?) ?? '',
      officeId: (row['office_id'] as String?) ?? '',
      officeName: (row['office_name'] as String?) ?? '',
      fullName: (row['full_name'] as String?) ?? '',
      phone: (row['phone'] as String?) ?? '',
      employeeCode: (row['employee_code'] as String?) ?? '',
    );
  }
}

/// Process-wide holder for the captain's identity.
///
/// Exists for the same reason [DashboardSession] does: every captain datasource is a
/// `registerLazySingleton` built before sign-in, so an office id captured at
/// construction would be permanently null. Holding the session and reading it per
/// query also fixes the pre-existing bug where `CaptainTripRemoteDataSource` cached a
/// `_cachedDriverId` that survived sign-out — [clear] now resets it for everyone.
class CaptainOfficeSession extends ChangeNotifier {
  CaptainIdentity? _identity;

  CaptainIdentity? get identity => _identity;

  bool get isAuthenticated => _identity != null;

  String? get driverIdOrNull => _identity?.driverId;

  String? get officeIdOrNull => _identity?.officeId;

  /// Throws when read while signed out, rather than returning null. A captain query
  /// that silently degraded to "no office filter" would be a cross-office leak.
  String get officeId {
    final id = _identity?.officeId;
    if (id == null || id.isEmpty) {
      throw StateError(
        'CaptainOfficeSession.officeId read while signed out. Resolve the captain '
        'before running an office-scoped query.',
      );
    }
    return id;
  }

  void start(CaptainIdentity identity) {
    _identity = identity;
    notifyListeners();
  }

  void clear() {
    if (_identity == null) return;
    _identity = null;
    notifyListeners();
  }
}
