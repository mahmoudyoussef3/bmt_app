import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_pricing.dart';
import '../../domain/repositories/trips_repository.dart';
import '../datasources/trips_datasource.dart';

class TripsRepositoryImpl implements TripsRepository {
  final TripsDatasource _datasource;

  const TripsRepositoryImpl(this._datasource);

  @override
  Future<List<OperationTrip>> getTrips() async {
    try {
      return await _datasource.fetchTrips();
    } catch (e) {
      throw Exception('تعذر تحميل الرحلات: ${e.toString()}');
    }
  }

  @override
  Future<OperationTrip> getTripById(String tripId) async {
    try {
      return await _datasource.fetchTripById(tripId);
    } catch (e) {
      throw Exception('تعذر تحميل تفاصيل الرحلة: ${e.toString()}');
    }
  }

  @override
  Future<OperationTrip> updateTripStatus(
    String tripId,
    OperationTripStatus status,
  ) async {
    try {
      return await _datasource.updateTripStatus(tripId, status);
    } catch (e) {
      throw Exception('تعذر تحديث حالة الرحلة: ${e.toString()}');
    }
  }

  @override
  Future<OperationTrip> updateSeatState(
    String tripId,
    String seatId,
    TripSeatState state,
  ) async {
    try {
      return await _datasource.updateSeatState(tripId, seatId, state);
    } catch (e) {
      throw Exception('تعذر تحديث حالة المقعد: ${e.toString()}');
    }
  }

  @override
  Future<OperationTrip> createTrip(CreateTripInput input) async {
    try {
      // 1. Basic field validations
      if (input.routeId.trim().isEmpty || input.route.trim().isEmpty) {
        throw Exception('المسار مطلوب لإنشاء رحلة.');
      }
      if (input.driverId.trim().isEmpty || input.driver.trim().isEmpty) {
        throw Exception('السائق مطلوب لإنشاء رحلة.');
      }
      if (input.vehicleId.trim().isEmpty || input.vehicle.trim().isEmpty) {
        throw Exception('المركبة مطلوبة لإنشاء رحلة.');
      }
      if (input.date.trim().isEmpty) {
        throw Exception('تاريخ الرحلة مطلوب.');
      }
      if (input.departure.trim().isEmpty) {
        throw Exception('وقت الانطلاق مطلوب.');
      }
      if (input.capacity <= 0) {
        throw Exception('سعة الركاب يجب أن تكون أكبر من صفر.');
      }

      // 2. Cannot create trip with archived route
      final routeStatus = await _datasource.getRouteStatus(input.routeId);
      if (routeStatus == 'archived') {
        throw Exception('لا يمكن جدولة رحلة لمسار مؤرشف.');
      }

      // 3. Cannot create trip with suspended or archived driver
      final driverStatus = await _datasource.getDriverStatus(input.driverId);
      if (driverStatus != 'active') {
        throw Exception('السائق غير نشط حالياً (حالة السائق: $driverStatus).');
      }

      // 4. Cannot create trip with maintenance, suspended, or archived vehicle
      final vehicleStatus = await _datasource.getVehicleStatus(input.vehicleId);
      if (vehicleStatus != 'active') {
        throw Exception('المركبة غير متاحة للتشغيل حالياً (حالة المركبة: $vehicleStatus).');
      }

      // 5. Cannot create duplicate trip for same vehicle/date/time
      final isDuplicate = await _datasource.checkDuplicateTrip(
        input.vehicleId,
        input.date,
        input.departure,
      );
      if (isDuplicate) {
        throw Exception('توجد رحلة مجدولة بالفعل لهذه المركبة في نفس التاريخ ووقت الانطلاق.');
      }

      return await _datasource.createTrip(input);
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('تعذر إنشاء الرحلة: ${e.toString()}');
    }
  }

  @override
  Future<OperationTrip> updateTripInfo(OperationTrip trip) async {
    try {
      if (trip.driverId.trim().isEmpty ||
          trip.vehicleId.trim().isEmpty ||
          trip.date.trim().isEmpty ||
          trip.departure.trim().isEmpty) {
        throw Exception('البيانات الأساسية للرحلة مطلوبة.');
      }

      // Check driver
      final driverStatus = await _datasource.getDriverStatus(trip.driverId);
      if (driverStatus != 'active') {
        throw Exception('السائق الجديد غير نشط حالياً.');
      }

      // Check vehicle
      final vehicleStatus = await _datasource.getVehicleStatus(trip.vehicleId);
      if (vehicleStatus != 'active') {
        throw Exception('المركبة الجديدة غير متاحة للتشغيل.');
      }

      return await _datasource.updateTripInfo(trip);
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('تعذر تحديث بيانات الرحلة: ${e.toString()}');
    }
  }

  @override
  Future<OperationTrip> updatePassenger(
    String tripId,
    TripPassenger passenger,
  ) async {
    try {
      if (passenger.name.trim().isEmpty) {
        throw Exception('اسم الراكب مطلوب.');
      }
      if (passenger.phone.trim().isEmpty) {
        throw Exception('رقم الهاتف للراكب مطلوب.');
      }
      return await _datasource.updatePassenger(tripId, passenger);
    } catch (e) {
      throw Exception('تعذر تعديل بيانات الراكب: ${e.toString()}');
    }
  }

  @override
  Future<OperationTrip> cancelPassenger(
    String tripId,
    String passengerId,
  ) async {
    try {
      return await _datasource.cancelPassenger(tripId, passengerId);
    } catch (e) {
      throw Exception('تعذر إلغاء الحجز: ${e.toString()}');
    }
  }

  @override
  Future<OperationTrip> movePassenger(
    String tripId,
    String passengerId,
    String seatLabel,
  ) async {
    try {
      return await _datasource.movePassenger(tripId, passengerId, seatLabel);
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('تعذر نقل الراكب: المقعد $seatLabel غير متاح حالياً.');
    }
  }

  @override
  Future<List<TripPricing>> getTripPricing(String tripId) async {
    try {
      return await _datasource.fetchTripPricing(tripId);
    } catch (e) {
      throw Exception('تعذر تحميل تسعير الرحلة: ${e.toString()}');
    }
  }

  @override
  Future<TripPricing> upsertTripPricing(TripPricing pricing) async {
    try {
      // Validation rules
      if (pricing.tripId.trim().isEmpty) {
        throw Exception('معرف الرحلة مطلوب.');
      }
      if (pricing.fromPointId == pricing.toPointId) {
        throw Exception('يجب أن تكون نقطتا البداية والنهاية مختلفتين.');
      }
      if (pricing.fromPointOrder >= pricing.toPointOrder) {
        throw Exception('نقطة البداية يجب أن تسبق نقطة النهاية في خط سير المسار.');
      }
      if (pricing.oneTimePrice <= 0 ||
          pricing.fiveDaysPrice <= 0 ||
          pricing.tenDaysPrice <= 0 ||
          pricing.monthlyPrice <= 0 ||
          pricing.threeMonthsPrice <= 0) {
        throw Exception('يجب أن تكون جميع قيم الأسعار أكبر من صفر.');
      }

      return await _datasource.upsertTripPricing(pricing);
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('تعذر حفظ التسعير: ${e.toString()}');
    }
  }

  @override
  Future<TripPricing> toggleTripPricingStatus(
    String pricingId,
    bool isActive,
  ) async {
    try {
      return await _datasource.toggleTripPricingStatus(pricingId, isActive);
    } catch (e) {
      throw Exception('تعذر تعديل حالة التسعير: ${e.toString()}');
    }
  }

  @override
  Future<List<TripEvent>> getTripEvents(String tripId) async {
    try {
      return await _datasource.fetchTripEvents(tripId);
    } catch (e) {
      throw Exception('تعذر تحميل سجل الأحداث: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveDrivers() {
    return _datasource.fetchActiveDrivers();
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveVehicles() {
    return _datasource.fetchActiveVehicles();
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveRoutes() {
    return _datasource.fetchActiveRoutes();
  }
}
