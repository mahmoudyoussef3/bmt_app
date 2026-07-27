import '../../domain/entities/trip_incident.dart';

/// Maps a `driver_trip_reports` row (with its trip/route/driver/vehicle embed)
/// into a [TripIncident].
class TripIncidentModel extends TripIncident {
  const TripIncidentModel({
    required super.id,
    required super.tripId,
    required super.type,
    required super.description,
    required super.status,
    required super.createdAt,
    super.resolvedAt,
    super.acknowledgedAt,
    super.resolutionNote,
    super.routeName,
    super.driverName,
    super.vehicleLabel,
    super.tripDate,
    super.departureTime,
  });

  factory TripIncidentModel.fromJson(Map<String, dynamic> json) {
    final trip = json['trip'] as Map<String, dynamic>?;
    final route = trip?['route'] as Map<String, dynamic>?;
    final driver = trip?['driver'] as Map<String, dynamic>?;
    final vehicle = trip?['vehicle'] as Map<String, dynamic>?;

    final plate = (vehicle?['plate_number'] as String?)?.trim() ?? '';
    final code = (vehicle?['vehicle_code'] as String?)?.trim() ?? '';

    return TripIncidentModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      type: IncidentType.fromDb(json['report_type'] as String? ?? 'other'),
      description: (json['description'] as String?)?.trim() ?? '',
      status: IncidentStatus.fromDb(json['status'] as String? ?? 'pending'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      resolvedAt: DateTime.tryParse(
        json['resolved_at'] as String? ?? '',
      )?.toLocal(),
      acknowledgedAt: DateTime.tryParse(
        json['acknowledged_at'] as String? ?? '',
      )?.toLocal(),
      resolutionNote: (json['resolution_note'] as String?)?.trim() ?? '',
      routeName: (route?['name'] as String?)?.trim() ?? '',
      driverName: (driver?['full_name'] as String?)?.trim() ?? '',
      vehicleLabel: plate.isNotEmpty ? plate : code,
      tripDate: (trip?['trip_date'] as String?) ?? '',
      departureTime: (trip?['departure_time'] as String?) ?? '',
    );
  }
}
