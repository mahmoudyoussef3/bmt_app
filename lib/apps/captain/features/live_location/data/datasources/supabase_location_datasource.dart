import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/captain/core/session/captain_identity_provider.dart';
import 'package:bmt_app/core/tracking/vehicle_fix.dart';

import '../models/location_sharing_model.dart';
import 'device_gps_datasource.dart';
import 'location_datasource.dart';

class SupabaseLocationDatasource implements LocationDatasource {
  SupabaseLocationDatasource(
    this._supabase,
    this._identity, {
    DeviceGpsDatasource gps = const DeviceGpsDatasource(),
  }) : _gps = gps;

  final SupabaseClient _supabase;
  final CaptainIdentityProvider _identity;
  final DeviceGpsDatasource _gps;

  /// The trip → vehicle pairing, resolved once per trip.
  ///
  /// This used to be a round trip on every single publish. That was tolerable at
  /// one write every 30 s; at the throttled cadence it would be a second query
  /// riding along with every fix, to re-learn something that cannot change while
  /// the trip runs — a trip takes a driver, and the vehicle is derived from the
  /// assignment, so re-reading it per fix buys nothing.
  String? _cachedTripId;
  String? _cachedVehicleId;

  @override
  Stream<VehicleFix> watchDevicePosition() => _gps.watchPosition();

  @override
  Future<LocationUpdateModel> sendLocation(String tripId) async {
    await _gps.ensureAvailable();
    return publishFix(tripId, await _gps.currentPosition());
  }

  @override
  Future<LocationUpdateModel> publishFix(String tripId, VehicleFix fix) async {
    final driverId = await _identity.driverId();
    if (driverId == null) {
      throw Exception('لا يمكن إرسال الموقع: لم يتم التعرف على السائق.');
    }

    final vehicleId = await _vehicleFor(tripId, driverId);

    // `driver_id` is stamped server-side by enforce_live_location_authorship
    // regardless of what is sent; it is included because the column is NOT NULL,
    // not because the value is trusted.
    await _supabase.from('trip_live_locations').insert({
      'trip_id': tripId,
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'latitude': fix.latitude,
      'longitude': fix.longitude,
      'accuracy': fix.accuracyMeters,
      'heading': fix.headingDegrees,
      'speed': fix.speedMetersPerSecond,
      'recorded_at': fix.recordedAt.toUtc().toIso8601String(),
    });

    return LocationUpdateModel(
      tripId: tripId,
      latitude: fix.latitude,
      longitude: fix.longitude,
      recordedAt: fix.recordedAt.toLocal(),
    );
  }

  Future<String> _vehicleFor(String tripId, String driverId) async {
    if (_cachedTripId == tripId && _cachedVehicleId != null) {
      return _cachedVehicleId!;
    }

    final trip = await _supabase
        .from('operation_trips')
        .select('vehicle_id')
        .eq('id', tripId)
        .eq('driver_id', driverId)
        .maybeSingle();

    final vehicleId = trip?['vehicle_id'] as String?;
    if (vehicleId == null) {
      throw Exception(
        'لا يمكن إرسال الموقع: لم يتم تعيين سائق ومركبة لهذه الرحلة.',
      );
    }

    _cachedTripId = tripId;
    _cachedVehicleId = vehicleId;
    return vehicleId;
  }
}
