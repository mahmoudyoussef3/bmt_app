import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'geo_models.dart';
import 'geo_service.dart';
import 'ors_config.dart';
import 'polyline_codec.dart';

/// OpenRouteService implementation of [GeoService].
///
/// Uses its OWN [Dio] instance (separate from the app's Supabase-bound
/// DioFactory) so no Supabase auth headers or base URL leak into ORS calls.
class OrsGeoService implements GeoService {
  OrsGeoService([Dio? dio]) : _dio = dio ?? _buildDio();

  final Dio _dio;

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: OrsConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'application/json'},
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(requestBody: true, error: true, compact: true),
      );
    }
    return dio;
  }

  @override
  bool get enabled => OrsConfig.geoEnabled;

  @override
  Future<List<GeoPlace>> autocomplete(String query, {GeoPoint? focus}) async {
    if (!enabled) {
      throw const GeoException('خدمة الخرائط غير مفعّلة (لا يوجد مفتاح).');
    }
    if (query.trim().length < 3) return const [];

    try {
      final response = await _dio.get(
        '/geocode/autocomplete',
        queryParameters: {
          'api_key': OrsConfig.apiKey,
          'text': query.trim(),
          'boundary.country': OrsConfig.countryCode,
          if (focus != null) 'focus.point.lon': focus.lng,
          if (focus != null) 'focus.point.lat': focus.lat,
          'size': 6,
        },
      );

      final features = (response.data['features'] as List?) ?? const [];
      return features
          .map(_placeFromFeature)
          .whereType<GeoPlace>()
          .toList(growable: false);
    } on DioException catch (e) {
      throw GeoException(_dioMessage(e, 'تعذّر البحث عن المكان'));
    }
  }

  @override
  Future<RouteGeometry> directions(List<GeoPoint> orderedPoints) async {
    if (!enabled) {
      throw const GeoException('خدمة الخرائط غير مفعّلة (لا يوجد مفتاح).');
    }
    if (orderedPoints.length < 2) {
      throw const GeoException('يلزم نقطتان على الأقل لحساب المسار.');
    }

    try {
      final response = await _dio.post(
        '/v2/directions/driving-car',
        options: Options(headers: {'Authorization': OrsConfig.apiKey}),
        data: {
          'coordinates': orderedPoints
              .map((p) => p.toLonLat())
              .toList(growable: false),
        },
      );

      final route =
          ((response.data['routes'] as List?) ?? const []).firstOrNull;
      if (route == null) {
        throw const GeoException('لم يتم العثور على مسار بين النقاط.');
      }

      final summary = route['summary'] as Map<String, dynamic>? ?? const {};
      final segments = (route['segments'] as List?) ?? const [];

      return RouteGeometry(
        totalDistanceMeters: (summary['distance'] as num?)?.toDouble() ?? 0,
        totalDurationSeconds: (summary['duration'] as num?)?.toDouble() ?? 0,
        path: PolylineCodec.decode(route['geometry']?.toString() ?? ''),
        legs: segments
            .map(
              (s) => RouteLeg(
                distanceMeters: (s['distance'] as num?)?.toDouble() ?? 0,
                durationSeconds: (s['duration'] as num?)?.toDouble() ?? 0,
              ),
            )
            .toList(growable: false),
      );
    } on DioException catch (e) {
      throw GeoException(_dioMessage(e, 'تعذّر حساب المسافة والمدة'));
    }
  }

  static GeoPlace? _placeFromFeature(dynamic feature) {
    if (feature is! Map) return null;
    final coords = (feature['geometry']?['coordinates'] as List?) ?? const [];
    if (coords.length < 2) return null;
    final lon = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();
    final label = feature['properties']?['label']?.toString() ?? '';
    if (label.isEmpty) return null;
    return GeoPlace(label: label, point: GeoPoint(lat, lon));
  }

  static String _dioMessage(DioException e, String fallback) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return 'مفتاح خدمة الخرائط غير صالح أو منتهي.';
    }
    if (status == 429) return 'تم تجاوز حد الطلبات اليومي لخدمة الخرائط.';
    if (e.type == DioExceptionType.connectionError) {
      return 'تعذّر الاتصال بخدمة الخرائط. تحقق من الإنترنت.';
    }
    return fallback;
  }
}
