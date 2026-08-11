import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _kSeenTripIdsKey = 'captain_seen_trip_ids';

class SeenTripsLocalDataSource {
  const SeenTripsLocalDataSource();

  Future<Set<String>> getSeenTripIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSeenTripIdsKey);
    if (raw == null) return {};
    try {
      return Set<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return {};
    }
  }

  Future<void> markSeen(Set<String> tripIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSeenTripIdsKey, jsonEncode(tripIds.toList()));
  }
}
