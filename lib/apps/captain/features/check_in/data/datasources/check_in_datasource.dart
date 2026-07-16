import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/captain/core/session/captain_driver_id_resolver.dart';

import '../../domain/entities/check_in_result.dart';
import '../models/check_in_model.dart';

const _kQueueKey = 'check_in_offline_queue';

class CheckInDataSource {
  const CheckInDataSource(this._supabase);

  final SupabaseClient _supabase;

  Future<CheckInModel> checkPassenger({
    required String tripId,
    required String bookingId,
    required CheckInStatus status,
  }) async {
    final driver = _supabase.auth.currentUser;
    if (driver == null) throw Exception('Driver not authenticated');

    final connectivity = await Connectivity().checkConnectivity();
    final offline =
        connectivity.contains(ConnectivityResult.none) ||
        (connectivity.length == 1 &&
            connectivity.first == ConnectivityResult.none);

    if (offline) {
      await _enqueue(tripId: tripId, bookingId: bookingId);
      // Not a confirmed board — the ticket hasn't been checked against the
      // booking yet. `flushOfflineQueue` runs the real validation once back
      // online; reporting `boarded` here would tell the captain a possibly
      // invalid or already-used ticket succeeded before anyone checked it.
      return CheckInModel(
        tripId: tripId,
        passengerId: bookingId,
        status: CheckInStatus.pendingSync,
        errorMessage: null,
      );
    }

    return _callRpc(tripId: tripId, bookingId: bookingId, driver: driver);
  }

  Future<int> flushOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kQueueKey) ?? [];
    if (raw.isEmpty) return 0;

    final driver = _supabase.auth.currentUser;
    if (driver == null) return 0;

    int flushed = 0;
    final remaining = <String>[];

    for (final entry in raw) {
      try {
        final map = jsonDecode(entry) as Map<String, dynamic>;
        await _callRpc(
          tripId: map['tripId'] as String,
          bookingId: map['bookingId'] as String,
          driver: driver,
        );
        flushed++;
      } catch (_) {
        remaining.add(entry);
      }
    }

    await prefs.setStringList(_kQueueKey, remaining);
    return flushed;
  }

  Future<int> get offlineQueueLength async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kQueueKey) ?? []).length;
  }

  Future<void> _enqueue({
    required String tripId,
    required String bookingId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_kQueueKey) ?? [];
    queue.add(
      jsonEncode({
        'tripId': tripId,
        'bookingId': bookingId,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
    await prefs.setStringList(_kQueueKey, queue);
  }

  Future<CheckInModel> _callRpc({
    required String tripId,
    required String bookingId,
    required User driver,
  }) async {
    final driverId = await resolveCaptainDriverId(_supabase, driver);
    if (driverId == null) {
      throw Exception('Driver profile not found');
    }

    // scan_passenger_ticket always returns a well-formed `success` payload for
    // every business outcome (invalid ticket, not approved, already checked
    // in) — see migration_07. A PostgrestException here is therefore never a
    // business answer; it's a real transport/permission/timeout failure, so
    // it must propagate as a genuine error rather than being reported as
    // "passenger absent". The caller (CheckInCubit.check / flushOfflineQueue)
    // already handles that.
    final response = await _supabase.rpc(
      'scan_passenger_ticket',
      params: {
        'p_trip_id': tripId,
        'p_booking_id': bookingId,
        'p_driver_id': driverId,
      },
    );

    return CheckInModel.fromRpcResponse(
      tripId: tripId,
      passengerId: bookingId,
      response: Map<String, dynamic>.from(response as Map),
    );
  }
}
