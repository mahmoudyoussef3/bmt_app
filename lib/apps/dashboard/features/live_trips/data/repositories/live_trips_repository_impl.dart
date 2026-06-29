import '../../domain/entities/live_trip.dart';
import '../../domain/repositories/live_trips_repository.dart';
import '../datasources/live_trips_datasource.dart';

class LiveTripsRepositoryImpl implements LiveTripsRepository {
  final LiveTripsDatasource _datasource;

  const LiveTripsRepositoryImpl(this._datasource);

  @override
  Future<List<LiveTrip>> getLiveTrips() async {
    try {
      return await _datasource.getLiveTrips();
    } catch (error) {
      throw Exception('تعذر تحميل الرحلات المباشرة: ${_cleanError(error)}');
    }
  }

  @override
  Future<LiveTrip> getLiveTripDetails(String tripId) async {
    try {
      return await _datasource.getLiveTripDetails(tripId);
    } catch (error) {
      throw Exception('تعذر تحميل تفاصيل الرحلة: ${_cleanError(error)}');
    }
  }

  @override
  Future<LiveTrip> startTrip(String tripId) async {
    try {
      return await _datasource.startTrip(tripId);
    } catch (error) {
      throw Exception('تعذر بدء الرحلة: ${_cleanError(error)}');
    }
  }

  @override
  Future<LiveTrip> pauseTrip(String tripId) async {
    try {
      return await _datasource.pauseTrip(tripId);
    } catch (error) {
      throw Exception('تعذر إيقاف الرحلة مؤقتًا: ${_cleanError(error)}');
    }
  }

  @override
  Future<LiveTrip> resumeTrip(String tripId) async {
    try {
      return await _datasource.resumeTrip(tripId);
    } catch (error) {
      throw Exception('تعذر استئناف الرحلة: ${_cleanError(error)}');
    }
  }

  @override
  Future<LiveTrip> completeTrip(String tripId) async {
    try {
      return await _datasource.completeTrip(tripId);
    } catch (error) {
      throw Exception('تعذر إنهاء الرحلة: ${_cleanError(error)}');
    }
  }

  @override
  Future<LiveTrip> markPointArrived(String tripId, String pointId) async {
    try {
      return await _datasource.markPointArrived(tripId, pointId);
    } catch (error) {
      throw Exception('تعذر تسجيل الوصول للمحطة: ${_cleanError(error)}');
    }
  }

  @override
  Future<LiveTrip> markPointCompleted(String tripId, String pointId) async {
    try {
      return await _datasource.markPointCompleted(tripId, pointId);
    } catch (error) {
      throw Exception('تعذر إنهاء المحطة: ${_cleanError(error)}');
    }
  }

  @override
  Future<LiveTrip> skipPoint(String tripId, String pointId) async {
    try {
      return await _datasource.skipPoint(tripId, pointId);
    } catch (error) {
      throw Exception('تعذر تخطي المحطة: ${_cleanError(error)}');
    }
  }

  @override
  Future<LiveTrip> resolveAlert(String tripId, String alertId) async {
    try {
      return await _datasource.resolveAlert(tripId, alertId);
    } catch (error) {
      throw Exception('تعذر حل التنبيه: ${_cleanError(error)}');
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
    } catch (error) {
      throw Exception('تعذر تسجيل التنبيه: ${_cleanError(error)}');
    }
  }

  @override
  Future<String> callDriver(String driverPhone) async {
    try {
      return await _datasource.callDriver(driverPhone);
    } catch (error) {
      throw Exception('تعذر الاتصال بالسائق: ${_cleanError(error)}');
    }
  }

  @override
  Future<String> sendDriverMessage(String driverPhone, String message) async {
    try {
      return await _datasource.sendDriverMessage(driverPhone, message);
    } catch (error) {
      throw Exception('تعذر إرسال الرسالة للسائق: ${_cleanError(error)}');
    }
  }

  @override
  Future<LiveTrip> togglePassengerCheckin(
    String tripId,
    String passengerId,
  ) async {
    try {
      return await _datasource.togglePassengerCheckin(tripId, passengerId);
    } catch (error) {
      throw Exception('تعذر تسجيل حضور/غياب الراكب: ${_cleanError(error)}');
    }
  }

  @override
  Stream<VehiclePosition> watchVehiclePosition(String tripId) {
    return _datasource.watchVehiclePosition(tripId);
  }

  @override
  Stream<void> watchTripStatusChanges() {
    return _datasource.watchTripStatusChanges();
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception: ?'), '');
  }
}
