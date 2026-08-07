import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/entitlements/licensing_guard.dart';
import '../../../../core/session/dashboard_session.dart';
import '../../domain/entities/operation_route.dart';
import '../models/operation_route_model.dart';
import 'routes_datasource.dart';

/// Real Supabase datasource for routes.
///
/// Important:
/// - No fake data.
/// - No local fallback.
/// - Any Supabase/database error is thrown clearly so you can fix the real issue.
class SupabaseRoutesDatasource implements RoutesDatasource {
  SupabaseRoutesDatasource(this._client, this._session);

  final SupabaseClient _client;
  final DashboardSession _session;

  // ── Fetch ────────────────────────────────────────────────────────────

  @override
  Future<List<OperationRouteModel>> fetchRoutes() async {
    try {
      debugPrint('[SupabaseRoutesDatasource] Loading routes...');

      final routesData = await _client
          .from('operation_routes')
          .select()
          .eq('office_id', _session.officeId)
          .order('created_at', ascending: false);

      // Stations carry no office of their own; they are fetched through the routes we
      // just loaded rather than as a full-table read that would span every office.
      final routeIds = routesData.map((r) => r['id'] as String).toList();
      final stationsData = routeIds.isEmpty
          ? const <Map<String, dynamic>>[]
          : await _client
                .from('route_stations')
                .select()
                .inFilter('route_id', routeIds)
                .order('sort_order');

      final stationsByRouteId = <String, List<RouteStationModel>>{};
      for (final json in stationsData) {
        final routeId = json['route_id'] as String;
        stationsByRouteId
            .putIfAbsent(routeId, () => [])
            .add(RouteStationModel.fromJson(json));
      }

      final routes = routesData.map<OperationRouteModel>((json) {
        final routeId = json['id'] as String;
        return OperationRouteModel.fromJson(
          json,
          stations: stationsByRouteId[routeId] ?? const [],
        );
      }).toList();

      debugPrint(
        '[SupabaseRoutesDatasource] Loaded ${routes.length} routes, '
        '${stationsData.length} stations.',
      );

      return routes;
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected Supabase fetch error: $e');
    }
  }

  // ── Create Route ─────────────────────────────────────────────────────

  @override
  Future<OperationRouteModel> createRoute(OperationRoute route) async {
    try {
      final routePayload = OperationRouteModel.fromEntity(route).toJson()
        ..['office_id'] = _session.officeId;

      final response = await _client
          .from('operation_routes')
          .insert(routePayload)
          .select()
          .single();

      final newRouteId = response['id'] as String;

      final stationModels = _prepareStations(route.stations);
      if (stationModels.isNotEmpty) {
        final stationPayloads = stationModels
            .map((s) => s.toJson(routeId: newRouteId))
            .toList();
        await _client.from('route_stations').insert(stationPayloads);
      }

      return _assembleRoute(newRouteId);
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected create route error: $e');
    }
  }

  // ── Update Route ─────────────────────────────────────────────────────

  @override
  Future<OperationRouteModel> updateRoute(OperationRoute route) async {
    try {
      final payload = OperationRouteModel.fromEntity(route).toJson();

      await _client.from('operation_routes').update(payload).eq('id', route.id);

      // Stations are part of the route, not a separate save. This used to write
      // only the `operation_routes` row, so every stop the operator added,
      // moved, renamed or removed in the builder was silently discarded.
      await _syncStations(route.id, route.stations);

      return _assembleRoute(route.id);
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected update route error: $e');
    }
  }

  @override
  Future<void> deleteRoute(String routeId) async {
    try {
      await _client.from('route_stations').delete().eq('route_id', routeId);
      await _client.from('operation_routes').delete().eq('id', routeId);
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected delete route error: $e');
    }
  }

  // ── Add Station ──────────────────────────────────────────────────────

  @override
  Future<OperationRouteModel> addStation(
    String routeId,
    RouteStation station,
  ) async {
    try {
      final currentStations = await _fetchStationsForRoute(routeId);
      final nextOrder = currentStations.isEmpty
          ? 1
          : currentStations.last.order + 1;

      final model = RouteStationModel.fromEntity(
        station.copyWith(order: nextOrder),
      );
      await _client
          .from('route_stations')
          .insert(model.toJson(routeId: routeId));

      return _assembleRoute(routeId);
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected add station error: $e');
    }
  }

  // ── Update Station ───────────────────────────────────────────────────

  @override
  Future<OperationRouteModel> updateStation(
    String routeId,
    RouteStation station,
  ) async {
    try {
      final model = RouteStationModel.fromEntity(station);
      await _client
          .from('route_stations')
          .update(model.toJson(routeId: routeId))
          .eq('id', station.id);

      return _assembleRoute(routeId);
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected update station error: $e');
    }
  }

  // ── Delete Station ───────────────────────────────────────────────────

  @override
  Future<OperationRouteModel> deleteStation(
    String routeId,
    String stationId,
  ) async {
    try {
      await _client.from('route_stations').delete().eq('id', stationId);

      // Re-normalize sort_order for remaining stations.
      await _normalizeStationOrder(routeId);

      return _assembleRoute(routeId);
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected delete station error: $e');
    }
  }

  // ── Reorder Stations ─────────────────────────────────────────────────

  @override
  Future<OperationRouteModel> reorderStations(
    String routeId,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      final stations = await _fetchStationsForRoute(routeId);
      final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final mutable = [...stations];
      final moved = mutable.removeAt(oldIndex);
      mutable.insert(adjustedIndex, moved);

      // Batch-update sort_order for each station.
      for (var i = 0; i < mutable.length; i++) {
        await _client
            .from('route_stations')
            .update({
              'sort_order': i + 1,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', mutable[i].id);
      }

      return _assembleRoute(routeId);
    } on PostgrestException catch (e) {
      throw Exception(_formatPostgrestError(e));
    } catch (e) {
      throw Exception('Unexpected reorder stations error: $e');
    }
  }

  // ── Private Helpers ──────────────────────────────────────────────────

  Future<OperationRouteModel> _assembleRoute(String routeId) async {
    final routeJson = await _client
        .from('operation_routes')
        .select()
        .eq('id', routeId)
        .single();

    final stations = await _fetchStationsForRoute(routeId);

    return OperationRouteModel.fromJson(routeJson, stations: stations);
  }

  Future<List<RouteStationModel>> _fetchStationsForRoute(String routeId) async {
    final data = await _client
        .from('route_stations')
        .select()
        .eq('route_id', routeId)
        .order('sort_order');

    return data
        .map<RouteStationModel>((json) => RouteStationModel.fromJson(json))
        .toList();
  }

  /// Makes `route_stations` match [stations] exactly: rows the operator dropped
  /// are deleted, new ones inserted, the rest updated in their new order.
  ///
  /// Rows that did not change are skipped, so status-only writes (pause,
  /// archive) — which pass the route's full station list along — don't rewrite
  /// every stop.
  Future<void> _syncStations(
    String routeId,
    List<RouteStation> stations,
  ) async {
    final existing = await _fetchStationsForRoute(routeId);
    final keptIds = stations
        .map((station) => station.id)
        .where((id) => id.isNotEmpty)
        .toSet();

    final removedIds = existing
        .map((station) => station.id)
        .where((id) => !keptIds.contains(id))
        .toList();
    if (removedIds.isNotEmpty) {
      await _client.from('route_stations').delete().inFilter('id', removedIds);
    }

    final existingById = {for (final station in existing) station.id: station};

    for (final entry in stations.indexed) {
      final (index, station) = entry;
      final model = RouteStationModel.fromEntity(
        station.copyWith(order: index + 1),
      );
      if (station.id.isEmpty) {
        await _client
            .from('route_stations')
            .insert(model.toJson(routeId: routeId));
        continue;
      }
      final current = existingById[station.id];
      if (current != null && _sameStation(current, model)) continue;
      await _client
          .from('route_stations')
          .update(model.toJson(routeId: routeId))
          .eq('id', station.id);
    }
  }

  static bool _sameStation(RouteStation a, RouteStation b) {
    return a.name == b.name &&
        a.area == b.area &&
        a.arrivalOffset == b.arrivalOffset &&
        a.departureOffset == b.departureOffset &&
        a.locationDescription == b.locationDescription &&
        a.notes == b.notes &&
        a.latitude == b.latitude &&
        a.longitude == b.longitude &&
        a.pickupAllowed == b.pickupAllowed &&
        a.dropoffAllowed == b.dropoffAllowed &&
        a.order == b.order;
  }

  Future<void> _normalizeStationOrder(String routeId) async {
    final stations = await _fetchStationsForRoute(routeId);
    for (var i = 0; i < stations.length; i++) {
      if (stations[i].order != i + 1) {
        await _client
            .from('route_stations')
            .update({
              'sort_order': i + 1,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', stations[i].id);
      }
    }
  }

  List<RouteStationModel> _prepareStations(List<RouteStation> stations) {
    return stations.indexed.map((entry) {
      final (index, station) = entry;
      return RouteStationModel.fromEntity(station.copyWith(order: index + 1));
    }).toList();
  }

  /// Every `on PostgrestException` in this class funnels here, so this is the
  /// single seat for the licensing guard on the routes surface (`routes` and
  /// `max_routes`, both trigger-enforced per §1.2 F4).
  String _formatPostgrestError(PostgrestException e) {
    LicensingGuard.check(e);

    final buffer = StringBuffer(e.message);

    if (e.code != null && e.code!.isNotEmpty) {
      buffer.write(' | code: ${e.code}');
    }

    if (e.details != null && e.details.toString().isNotEmpty) {
      buffer.write(' | details: ${e.details}');
    }

    if (e.hint != null && e.hint.toString().isNotEmpty) {
      buffer.write(' | hint: ${e.hint}');
    }

    return buffer.toString();
  }
}
