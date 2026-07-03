import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/location_sharing_model.dart';
import 'location_datasource.dart';

class SupabaseLocationDatasource implements LocationDatasource {
  const SupabaseLocationDatasource(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<LocationUpdateModel> sendLocation(String tripId) async {
    await _ensureLocationAvailable();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    final recordedAt = position.timestamp;

    await _supabase.from('trip_live_locations').insert({
      'trip_id': tripId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'heading': position.heading,
      'speed': position.speed,
      'recorded_at': recordedAt.toUtc().toIso8601String(),
    });

    return LocationUpdateModel(
      tripId: tripId,
      latitude: position.latitude,
      longitude: position.longitude,
      recordedAt: recordedAt.toLocal(),
    );
  }

  Future<void> _ensureLocationAvailable() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('فعّل خدمة الموقع في الهاتف ثم حاول مرة أخرى.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('يلزم السماح بالوصول للموقع لإرسال موقعك الحالي.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'صلاحية الموقع مرفوضة نهائياً. فعّلها من إعدادات التطبيق.',
      );
    }
  }
}
