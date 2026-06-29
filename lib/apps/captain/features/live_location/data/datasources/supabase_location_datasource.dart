import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/background/location_background_service.dart';
import '../models/location_sharing_model.dart';
import 'location_datasource.dart';

class SupabaseLocationDatasource implements LocationDatasource {
  SupabaseLocationDatasource(this._supabase);

  final SupabaseClient _supabase;

  // Foreground stream used on iOS (and as fallback on other platforms).
  StreamSubscription<Position>? _iosForegroundSub;
  RealtimeChannel? _iosChannel;

  @override
  Future<LocationSharingModel> startSharing(String tripId) async {
    final permission = await _ensurePermission();
    if (!permission) {
      return LocationSharingModel(tripId: tripId, enabled: false);
    }

    if (Platform.isAndroid) {
      await startLocationService(tripId);
    } else {
      await _startForegroundSharing(tripId);
    }

    return LocationSharingModel(tripId: tripId, enabled: true);
  }

  @override
  Future<LocationSharingModel> stopSharing(String tripId) async {
    if (Platform.isAndroid) {
      await stopLocationService();
    } else {
      await _stopForegroundSharing();
    }
    return LocationSharingModel(tripId: tripId, enabled: false);
  }

  Future<void> _startForegroundSharing(String tripId) async {
    await _stopForegroundSharing();

    final channel = _supabase.channel('live_location:$tripId')..subscribe();
    _iosChannel = channel;

    _iosForegroundSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      channel.sendBroadcastMessage(
        event: 'location',
        payload: {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'accuracy': pos.accuracy,
          'speed': pos.speed,
          'recorded_at': pos.timestamp.toIso8601String(),
        },
      );
      // Persist to DB every position update (foreground mode — low frequency
      // thanks to distanceFilter so this is acceptable).
      _supabase.from('trip_live_locations').insert({
        'trip_id': tripId,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'accuracy': pos.accuracy,
        'recorded_at': DateTime.now().toIso8601String(),
      }).catchError((_) {});
    });
  }

  Future<void> _stopForegroundSharing() async {
    await _iosForegroundSub?.cancel();
    _iosForegroundSub = null;
    await _iosChannel?.unsubscribe();
    _iosChannel = null;
  }

  Future<bool> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
