import '../../domain/entities/live_trip.dart';
import '../../domain/repositories/live_trips_repository.dart';
import '../datasources/mock_live_trips_datasource.dart';

class LiveTripsRepositoryImpl implements LiveTripsRepository {
  final LiveTripsDatasource _datasource;

  const LiveTripsRepositoryImpl(this._datasource);

  @override
  Future<List<LiveTrip>> getLiveTrips() async {
    try {
      return await _datasource.getLiveTrips();
    } catch (_) {
      throw Exception('تعذر تحميل الرحلات المباشرة');
    }
  }

  @override
  Future<LiveTrip> getLiveTripDetails(String tripId) async {
    try {
      return await _datasource.getLiveTripDetails(tripId);
    } catch (_) {
      throw Exception('تعذر تحميل تفاصيل الرحلة');
    }
  }

  @override
  Future<LiveTrip> startTrip(String tripId) async {
    try {
      return await _datasource.startTrip(tripId);
    } catch (_) {
      throw Exception('تعذر بدء الرحلة');
    }
  }

  @override
  Future<LiveTrip> pauseTrip(String tripId) async {
    try {
      return await _datasource.pauseTrip(tripId);
    } catch (_) {
      throw Exception('تعذر إيقاف الرحلة مؤقتًا');
    }
  }

  @override
  Future<LiveTrip> resumeTrip(String tripId) async {
    try {
      return await _datasource.resumeTrip(tripId);
    } catch (_) {
      throw Exception('تعذر استئناف الرحلة');
    }
  }

  @override
  Future<LiveTrip> completeTrip(String tripId) async {
    try {
      return await _datasource.completeTrip(tripId);
    } catch (_) {
      throw Exception('تعذر إنهاء الرحلة');
    }
  }

  @override
  Future<LiveTrip> markPointArrived(String tripId, String pointId) async {
    try {
      return await _datasource.markPointArrived(tripId, pointId);
    } catch (_) {
      throw Exception('تعذر تسجيل الوصول للمحطة');
    }
  }

  @override
  Future<LiveTrip> markPointCompleted(String tripId, String pointId) async {
    try {
      return await _datasource.markPointCompleted(tripId, pointId);
    } catch (_) {
      throw Exception('تعذر إنهاء المحطة');
    }
  }

  @override
  Future<LiveTrip> skipPoint(String tripId, String pointId) async {
    try {
      return await _datasource.skipPoint(tripId, pointId);
    } catch (_) {
      throw Exception('تعذر تخطي المحطة');
    }
  }

  @override
  Future<LiveTrip> resolveAlert(String tripId, String alertId) async {
    try {
      return await _datasource.resolveAlert(tripId, alertId);
    } catch (_) {
      throw Exception('تعذر حل التنبيه');
    }
  }

  @override
  Future<LiveTrip> reportAlert({
    required String tripId,
    required LiveTripAlertType type,
    required LiveTripAlertSeverity severity,
    required String title,
    required String message,
  }) async {
    try {
      return await _datasource.reportAlert(
        tripId: tripId,
        type: type,
        severity: severity,
        title: title,
        message: message,
      );
    } catch (_) {
      throw Exception('تعذر تسجيل التنبيه');
    }
  }

  @override
  Future<String> callDriver(String driverPhone) async {
    try {
      return await _datasource.callDriver(driverPhone);
    } catch (_) {
      throw Exception('تعذر الاتصال بالسائق');
    }
  }

  @override
  Future<String> sendDriverMessage(String driverPhone, String message) async {
    try {
      return await _datasource.sendDriverMessage(driverPhone, message);
    } catch (_) {
      throw Exception('تعذر إرسال الرسالة للسائق');
    }
  }
}
