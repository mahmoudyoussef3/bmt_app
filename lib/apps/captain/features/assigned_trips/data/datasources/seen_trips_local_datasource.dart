import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _kSeenTripIdsKey = 'captain_seen_trip_ids';

/// Tracks which assigned trips this captain has already been shown on the
/// home screen — purely on-device, since there's no "seen" concept on the
/// backend. A trip id absent from this set is what backs the "new
/// assignment" notice on Home.
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

  /// Replaces the whole seen-set with exactly [tripIds] — the full set of
  /// trips currently visible to the captain, not an ever-growing log. A trip
  /// that later drops off the list (completed and outside the query's
  /// window) naturally drops out of the seen-set too.
  Future<void> markSeen(Set<String> tripIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSeenTripIdsKey, jsonEncode(tripIds.toList()));
  }
}
