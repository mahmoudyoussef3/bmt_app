import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CaptainLocalSession {
  final String driverId;
  final String name;
  final String phone;
  final String employeeCode;

  const CaptainLocalSession({
    required this.driverId,
    required this.name,
    required this.phone,
    this.employeeCode = '',
  });

  Map<String, dynamic> toJson() => {
    'driver_id': driverId,
    'name': name,
    'phone': phone,
    'employee_code': employeeCode,
  };

  factory CaptainLocalSession.fromJson(Map<String, dynamic> json) =>
      CaptainLocalSession(
        driverId: json['driver_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        employeeCode: json['employee_code'] as String? ?? '',
      );
}

class CaptainSessionStore {
  static const _pendingKey = 'captain_pending_phone';
  static const _sessionKey = 'captain_local_session';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> savePendingPhone(String phone) async {
    final prefs = await _prefs;
    await prefs.setString(_pendingKey, phone);
  }

  Future<String?> readPendingPhone() async {
    final prefs = await _prefs;
    return prefs.getString(_pendingKey);
  }

  Future<void> clearPending() async {
    final prefs = await _prefs;
    await prefs.remove(_pendingKey);
  }

  Future<void> saveSession(CaptainLocalSession session) async {
    final prefs = await _prefs;
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    await prefs.remove(_pendingKey);
  }

  Future<CaptainLocalSession?> readSession() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;
    try {
      return CaptainLocalSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_sessionKey);
    await prefs.remove(_pendingKey);
  }
}
