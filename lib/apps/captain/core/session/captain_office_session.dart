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
    this.licensing = const CaptainLicensing(),
  });

  final String driverId;
  final String officeId;
  final String officeName;
  final String fullName;
  final String phone;
  final String employeeCode;

  /// What the office's platform licence permits this app to do.
  final CaptainLicensing licensing;

  factory CaptainIdentity.fromRpc(Map<String, dynamic> row) {
    return CaptainIdentity(
      driverId: (row['driver_id'] as String?) ?? '',
      officeId: (row['office_id'] as String?) ?? '',
      officeName: (row['office_name'] as String?) ?? '',
      fullName: (row['full_name'] as String?) ?? '',
      phone: (row['phone'] as String?) ?? '',
      employeeCode: (row['employee_code'] as String?) ?? '',
      licensing: CaptainLicensing.fromRpc(row['licensing']),
    );
  }
}

/// The office's licensing state, as it affects the captain app.
///
/// Resolved SERVER-SIDE and handed over in `captain_session_context` — the
/// captain app holds no entitlement context of its own and must not be trusted
/// to gate itself.
///
/// **The mid-trip rule is absolute.** No licensing state may interrupt a trip
/// that has started or a ticket already sold, so [blocked] is false whenever
/// [inFlight] is true, whatever the office owes. This is the one gate in the
/// whole entitlement platform where the alternative has physical consequences.
@immutable
class CaptainLicensing {
  const CaptainLicensing({
    this.driverApp = true,
    this.liveTracking = true,
    this.inFlight = false,
    this.blocked = false,
    this.messageAr,
  });

  /// Is the captain app licensed for this office at all?
  final bool driverApp;

  /// Is live location publishing licensed? When false the app stops the
  /// publisher; the trip flow itself is untouched.
  final bool liveTracking;

  /// Does this captain have a trip boarding or in progress right now?
  final bool inFlight;

  /// Refuse the session. Already accounts for [inFlight] and for the platform's
  /// enforcement mode, so the app never has to re-derive the rule.
  final bool blocked;

  final String? messageAr;

  /// Permissive by default: an older server, or a payload without the key,
  /// behaves exactly as the app did before licensing existed.
  factory CaptainLicensing.fromRpc(Object? raw) {
    if (raw is! Map) return const CaptainLicensing();
    final map = Map<String, dynamic>.from(raw);
    return CaptainLicensing(
      driverApp: map['driver_app'] != false,
      liveTracking: map['live_tracking'] != false,
      inFlight: map['in_flight'] == true,
      blocked: map['blocked'] == true,
      messageAr: map['message_ar'] as String?,
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
