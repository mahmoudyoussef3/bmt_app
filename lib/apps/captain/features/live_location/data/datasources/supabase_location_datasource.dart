import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/location_sharing_model.dart';
import 'location_datasource.dart';

class SupabaseLocationDatasource implements LocationDatasource {
  SupabaseLocationDatasource(this._supabase);

  final SupabaseClient _supabase;
  StreamSubscription<Position>? _positionSub;
  Timer? _persistTimer;
  RealtimeChannel? _channel;
  Position? _latest;

  @override
  Future<LocationSharingModel> startSharing(String tripId) async {
    final permission = await _ensurePermission();
    if (!permission) {
      return LocationSharingModel(tripId: tripId, enabled: false);
    }

    await _stop(tripId);

    _channel = _supabase.channel('live_location:$tripId');
    _channel!.subscribe();

    _positionSub = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 5),
      ),
    ).listen((pos) {
      _latest = pos;
      _channel?.sendBroadcastMessage(
        event: 'location',
        payload: {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'accuracy': pos.accuracy,
          'speed': pos.speed,
        },
      );
    });

    // Persist to DB every 30 s
    _persistTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_latest == null) return;
      try {
        await _supabase.from('trip_live_locations').insert({
          'trip_id': tripId,
          'latitude': _latest!.latitude,
          'longitude': _latest!.longitude,
          'accuracy': _latest!.accuracy,
          'recorded_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    });

    return LocationSharingModel(tripId: tripId, enabled: true);
  }

  @override
  Future<LocationSharingModel> stopSharing(String tripId) async {
    await _stop(tripId);
    return LocationSharingModel(tripId: tripId, enabled: false);
  }

  Future<void> _stop(String tripId) async {
    _positionSub?.cancel();
    _positionSub = null;
    _persistTimer?.cancel();
    _persistTimer = null;
    await _channel?.unsubscribe();
    _channel = null;
    _latest = null;
  }

  Future<bool> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
