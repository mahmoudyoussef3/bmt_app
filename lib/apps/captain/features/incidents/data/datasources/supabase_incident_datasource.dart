import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/incident_report.dart';
import '../models/incident_report_model.dart';
import 'incident_datasource.dart';

class SupabaseIncidentDatasource implements IncidentDatasource {
  const SupabaseIncidentDatasource(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<IncidentReportModel> reportIncident(IncidentReport report) async {
    final driverId = _supabase.auth.currentUser?.id ?? '';
    await _supabase.from('driver_trip_reports').insert({
      'trip_id': report.tripId,
      'driver_id': driverId,
      'report_type': _typeToDb(report.type),
      'description': report.description,
      'status': 'pending',
    });
    return IncidentReportModel(
      tripId: report.tripId,
      type: report.type,
      description: report.description,
    );
  }

  String _typeToDb(IncidentType type) => switch (type) {
    IncidentType.passengerIssue => 'passenger_issue',
    IncidentType.vehicleIssue   => 'vehicle_issue',
    IncidentType.delay          => 'delay',
    IncidentType.emergency      => 'emergency',
    IncidentType.routeBlockage  => 'route_blockage',
    IncidentType.other          => 'other',
  };
}
