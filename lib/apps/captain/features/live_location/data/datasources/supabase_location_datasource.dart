import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../../../../core/background/location_background_service.dart';
import '../models/location_sharing_model.dart';
import 'location_datasource.dart';

class SupabaseLocationDatasource implements LocationDatasource {
  SupabaseLocationDatasource(this._unused);

  // Kept for DI compatibility — background service manages its own Supabase client.
  // ignore: unused_field
  final dynamic _unused;

  @override
  Future<LocationSharingModel> startSharing(String tripId) async {
    final permission = await _ensurePermission();
    if (!permission) {
      return LocationSharingModel(tripId: tripId, enabled: false);
    }

    if (Platform.isAndroid) {
      await startLocationService(tripId);
    }

    return LocationSharingModel(tripId: tripId, enabled: true);
  }

  @override
  Future<LocationSharingModel> stopSharing(String tripId) async {
    if (Platform.isAndroid) {
      await stopLocationService();
    }
    return LocationSharingModel(tripId: tripId, enabled: false);
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
