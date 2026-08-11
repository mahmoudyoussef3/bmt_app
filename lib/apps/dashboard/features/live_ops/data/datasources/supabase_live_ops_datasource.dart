import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/session/dashboard_session.dart';
import '../../domain/entities/trip_incident.dart';
import '../models/live_trip_model.dart';
import '../models/trip_incident_model.dart';
import 'live_ops_datasource.dart';

/// Reads the live operational picture for the signed-in office.
///
/// Office isolation is enforced by RLS on every table this touches:
/// `operation_trips` (office policy), `driver_trip_reports`
/// (`driver_trip_reports_office_manage`) and, since migration
/// `20260729090000`, `trip_live_locations` (`trip_live_locations_read`, which
/// admits the operating office among the four parties allowed to look).
///
/// Positions still come from the `dashboard_active_trip_fixes` RPC rather than
/// a direct read. The RPC predates the policy and was written to compensate for
/// its absence, but it earns its place independently: it returns one latest fix
/// per active trip in a single `distinct on` rather than making the board fetch
/// a feed per vehicle and reduce it client-side.
class SupabaseLiveOpsDatasource implements LiveOpsDatasource {
  final SupabaseClient _client;
  final DashboardSession _session;

  const SupabaseLiveOpsDatasource(this._client, this._session);

  static const _activeStatuses = ['boarding', 'in_progress'];

  /// Not-yet-closed reports. `acknowledged` is included deliberately: a report
  /// someone is actively working must stay on the board, or the operator
  /// handling it loses the thread the moment they claim it.
  static const _openIncidentStatuses = ['pending', 'acknowledged'];

  @override
  Future<List<LiveTripModel>> fetchActiveTrips() async {
    try {
      final tripRows = await _client
          .from('operation_trips')
          .select('''
            id, trip_date, departure_time, status, capacity, actual_start_time,
            route:operation_routes(name),
            driver:drivers(full_name, phone),
            vehicle:vehicles(plate_number, vehicle_code),
            seats:trip_seats(state)
          ''')
          .eq('office_id', _session.officeId)
          .inFilter('status', _activeStatuses)
          .order('departure_time', ascending: true);

      final trips = (tripRows as List).cast<Map<String, dynamic>>();
      if (trips.isEmpty) return const [];

      final latestByTrip = await _latestFixByTrip();

      return trips
          .map(
            (t) =>
                LiveTripModel.fromRows(t, fix: latestByTrip[t['id'] as String]),
          )
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Latest fix per active trip, one row each, resolved server-side.
  ///
  /// The RPC does the `DISTINCT ON (trip_id) … ORDER BY recorded_at DESC` in
  /// Postgres against the `(trip_id, recorded_at DESC)` index. Reading the table
  /// directly instead would pull every fix ever recorded for every active trip
  /// on each 15s poll — at the captain's 30s publish cadence that is ~360 rows
  /// per trip-hour, to use one of them.
  ///
  /// A failure here is swallowed: positions are an enrichment, and a desk that
  /// can still see *which* trips are running with their tracking marked unknown
  /// is far more useful than an error screen.
  Future<Map<String, Map<String, dynamic>>> _latestFixByTrip() async {
    try {
      final rows = await _client.rpc(
        'dashboard_active_trip_fixes',
        params: {'p_office_id': _session.officeId},
      );

      return {
        for (final row in (rows as List).cast<Map<String, dynamic>>())
          row['trip_id'] as String: row,
      };
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<List<TripIncidentModel>> fetchOpenIncidents() async {
    try {
      
      final rows = await _client
          .from('driver_trip_reports')
          .select('''
            id, trip_id, report_type, description, status, resolved_at, created_at,
            acknowledged_at, resolution_note,
            trip:operation_trips!inner(
              trip_date, departure_time,
              route:operation_routes(name),
              driver:drivers(full_name),
              vehicle:vehicles(plate_number, vehicle_code)
            )
          ''')
          .inFilter('status', _openIncidentStatuses)
          .order('created_at', ascending: false);

      return (rows as List)
          .map((r) => TripIncidentModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus next,
    String? note,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final actor = _client.auth.currentUser?.id;

      final payload = <String, dynamic>{'status': next.db};

      switch (next) {
        case IncidentStatus.acknowledged:
          payload['acknowledged_at'] = now;
          payload['acknowledged_by'] = actor;
        case IncidentStatus.resolved || IncidentStatus.dismissed:
          payload['resolved_at'] = now;
          payload['resolved_by'] = actor;
        case IncidentStatus.pending:
          break;
      }

      final trimmed = note?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        payload['resolution_note'] = trimmed;
      }

      await _client
          .from('driver_trip_reports')
          .update(payload)
          .eq('id', incidentId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Stream<void> watchChanges() {
    final controller = StreamController<void>.broadcast();
    void notify(PostgresChangePayload _) {
      if (!controller.isClosed) controller.add(null);
    }

    final channel = _client
        .channel('dashboard_live_ops_${_session.officeId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'operation_trips',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'office_id',
            value: _session.officeId,
          ),
          callback: notify,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'driver_trip_reports',
          callback: notify,
        );

    final subscribed = channel.subscribe();
    controller.onCancel = subscribed.unsubscribe;
    return controller.stream;
  }

  Exception _handleError(dynamic error) {
    if (error is PostgrestException) {
      return Exception('خطأ بقاعدة البيانات: ${error.message} (${error.code})');
    }
    return Exception(error.toString());
  }
}
