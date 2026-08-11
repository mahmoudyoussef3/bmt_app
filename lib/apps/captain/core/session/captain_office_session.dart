import 'package:flutter/foundation.dart';

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

@immutable
class CaptainLicensing {
  const CaptainLicensing({
    this.driverApp = true,
    this.liveTracking = true,
    this.inFlight = false,
    this.blocked = false,
    this.messageAr,
  });

  final bool driverApp;

  final bool liveTracking;

  final bool inFlight;

  final bool blocked;

  final String? messageAr;

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

class CaptainOfficeSession extends ChangeNotifier {
  CaptainIdentity? _identity;

  CaptainIdentity? get identity => _identity;

  bool get isAuthenticated => _identity != null;

  String? get driverIdOrNull => _identity?.driverId;

  String? get officeIdOrNull => _identity?.officeId;

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
