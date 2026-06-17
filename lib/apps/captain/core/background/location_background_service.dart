import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kTripIdKey = 'bg_service_trip_id';

// Supabase credentials — same values used in main_captain.dart
const _supabaseUrl = 'https://nbwzourpbnmewwklewyr.supabase.co';
const _supabaseAnonKey = 'sb_publishable_EHODbNyFC_qJI1fZuETNKA_uu9hUU8Z';

/// Configures the background service. Call once at app startup.
Future<void> initLocationBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onServiceStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'bmt_location_channel',
      initialNotificationTitle: 'BMT — مشاركة الموقع',
      initialNotificationContent: 'جاري مشاركة موقعك مع العمليات',
      foregroundServiceNotificationId: 8801,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
}

/// Stores [tripId] in prefs then starts the foreground service.
Future<void> startLocationService(String tripId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kTripIdKey, tripId);
  await FlutterBackgroundService().startService();
}

/// Sends a stop event to the running service.
Future<void> stopLocationService() async {
  FlutterBackgroundService().invoke('stopService');
}

Future<bool> get isLocationServiceRunning =>
    FlutterBackgroundService().isRunning();

// ---------------------------------------------------------------------------
// Background isolate entry point
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
void _onServiceStart(ServiceInstance service) async {
  // Must be called before any async gap in the background isolate.
  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final tripId = prefs.getString(_kTripIdKey);

  if (tripId == null) {
    service.stopSelf();
    return;
  }

  // Initialize Supabase in the background isolate.
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseAnonKey);
  final supabase = Supabase.instance.client;

  // Open broadcast channel.
  final channel = supabase.channel('live_location:$tripId')..subscribe();

  Position? latest;
  StreamSubscription<Position>? positionSub;
  Timer? persistTimer;

  Future<void> cleanup() async {
    positionSub?.cancel();
    persistTimer?.cancel();
    await channel.unsubscribe();
    service.stopSelf();
  }

  // Stop on request from main isolate.
  service.on('stopService').listen((_) => cleanup());

  // Start GPS stream.
  positionSub = Geolocator.getPositionStream(
    locationSettings: AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      intervalDuration: Duration(seconds: 5),
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationText: 'BMT يتتبع موقعك',
        notificationTitle: 'مشاركة الموقع',
        enableWakeLock: true,
      ),
    ),
  ).listen((pos) {
    latest = pos;
    channel.sendBroadcastMessage(
      event: 'location',
      payload: {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'accuracy': pos.accuracy,
        'speed': pos.speed,
      },
    );
    // Keep notification content current.
    service.invoke('update', {
      'lat': pos.latitude.toStringAsFixed(5),
      'lng': pos.longitude.toStringAsFixed(5),
    });
  });

  // Persist to DB every 30 s.
  persistTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
    if (latest == null) return;
    try {
      await supabase.from('trip_live_locations').insert({
        'trip_id': tripId,
        'latitude': latest!.latitude,
        'longitude': latest!.longitude,
        'accuracy': latest!.accuracy,
        'recorded_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  });
}
