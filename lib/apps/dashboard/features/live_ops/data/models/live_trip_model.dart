import '../../../trips/shared/domain/entities/operation_trip.dart';
import '../../domain/entities/live_ops_snapshot.dart';

/// Maps an `operation_trips` row (with its route/driver/vehicle/seats embeds)
/// plus an optional latest `trip_live_locations` row into a [LiveTrip].
class LiveTripModel extends LiveTrip {
  const LiveTripModel({
    required super.id,
    required super.statusLabel,
    required super.isInProgress,
    required super.routeName,
    required super.driverName,
    required super.driverPhone,
    required super.vehicleLabel,
    required super.tripDate,
    required super.departureTime,
    required super.capacity,
    required super.bookedSeats,
    super.lastFix,
    super.scheduledDeparture,
    super.actualStart,
  });

  factory LiveTripModel.fromRows(
    Map<String, dynamic> trip, {
    Map<String, dynamic>? fix,
  }) {
    final rawStatus = trip['status'] as String? ?? 'in_progress';
    final status = OperationTripStatus.fromString(rawStatus);

    final route = trip['route'] as Map<String, dynamic>?;
    final driver = trip['driver'] as Map<String, dynamic>?;
    final vehicle = trip['vehicle'] as Map<String, dynamic>?;
    final seats = (trip['seats'] as List?) ?? const [];

    final plate = (vehicle?['plate_number'] as String?)?.trim() ?? '';
    final code = (vehicle?['vehicle_code'] as String?)?.trim() ?? '';

    final tripDate = (trip['trip_date'] as String?) ?? '';
    final departureTime = (trip['departure_time'] as String?) ?? '';

    return LiveTripModel(
      id: trip['id'] as String,
      statusLabel: status.label,
      isInProgress: status == OperationTripStatus.inProgress,
      routeName: (route?['name'] as String?)?.trim() ?? 'مسار غير معروف',
      driverName: (driver?['full_name'] as String?)?.trim() ?? 'غير معيّن',
      driverPhone: (driver?['phone'] as String?)?.trim() ?? '',
      vehicleLabel: plate.isNotEmpty
          ? plate
          : (code.isNotEmpty ? code : 'مركبة غير معروفة'),
      tripDate: tripDate,
      departureTime: departureTime,
      capacity: (trip['capacity'] as num?)?.toInt() ?? 0,
      bookedSeats: _countBooked(seats),
      lastFix: _parseFix(fix),
      scheduledDeparture: _parseSchedule(tripDate, departureTime),
      actualStart: DateTime.tryParse(
        trip['actual_start_time'] as String? ?? '',
      )?.toLocal(),
    );
  }

  /// Combines the `date` + `time` columns into one local instant.
  ///
  /// Both are stored without a zone (`date` / `time without time zone`) and mean
  /// office-local wall-clock, so they are assembled as local time — the same
  /// clock the operator reading the screen is on. Returns `null` if either part
  /// is missing or malformed, which makes the domain skip delay reporting
  /// entirely rather than measure against a guessed time.
  static DateTime? _parseSchedule(String date, String time) {
    if (date.isEmpty || time.isEmpty) return null;
    // `time` arrives as HH:mm or HH:mm:ss; DateTime.tryParse needs seconds.
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final normalized = parts.length == 2 ? '$time:00' : time;
    return DateTime.tryParse('${date}T$normalized');
  }

  static int _countBooked(List<dynamic> seats) {
    const booked = {'reserved', 'paid', 'subscription'};
    return seats
        .whereType<Map<String, dynamic>>()
        .where((s) => booked.contains(s['state'] as String?))
        .length;
  }

  static LiveFix? _parseFix(Map<String, dynamic>? fix) {
    if (fix == null) return null;
    final lat = (fix['latitude'] as num?)?.toDouble();
    final lng = (fix['longitude'] as num?)?.toDouble();
    final recordedAt = DateTime.tryParse(fix['recorded_at'] as String? ?? '');
    if (lat == null || lng == null || recordedAt == null) return null;

    // Captain publishes `speed` in metres/second (Geolocator); the desk reads
    // km/h.
    final speedMs = (fix['speed'] as num?)?.toDouble();
    return LiveFix(
      latitude: lat,
      longitude: lng,
      recordedAt: recordedAt.toLocal(),
      heading: (fix['heading'] as num?)?.toDouble(),
      speedKph: speedMs == null ? null : speedMs * 3.6,
    );
  }
}
