import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  SupabaseRoutesDatasource(this._client);

  final SupabaseClient _client;

  // ── Fetch ────────────────────────────────────────────────────────────

  @override
  Future<List<OperationRouteModel>> fetchRoutes() async {
    try {
      debugPrint('[SupabaseRoutesDatasource] Loading routes...');

      final routesData = await _client
          .from('operation_routes')
          .select()
          .order('created_at', ascending: false);

      final stationsData = await _client
          .from('route_stations')
          .select()
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
      final routePayload = OperationRouteModel.fromEntity(route).toJson();

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

  String _formatPostgrestError(PostgrestException e) {
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
