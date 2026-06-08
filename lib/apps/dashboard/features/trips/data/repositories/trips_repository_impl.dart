import '../../domain/entities/operation_trip.dart';
import '../../domain/entities/trip_pricing.dart';
import '../../domain/repositories/trips_repository.dart';
import '../datasources/mock_trips_datasource.dart';

class TripsRepositoryImpl implements TripsRepository {
  final TripsDatasource _datasource;

  const TripsRepositoryImpl(this._datasource);

  @override
  Future<List<OperationTrip>> getTrips() async {
    try {
      return await _datasource.fetchTrips();
    } catch (_) {
      throw Exception('تعذر تحميل الرحلات');
    }
  }

  @override
  Future<OperationTrip> updateTripStatus(
    String tripId,
    OperationTripStatus status,
  ) async {
    try {
      return await _datasource.updateTripStatus(tripId, status);
    } catch (_) {
      throw Exception('تعذر تحديث حالة الرحلة');
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
    } catch (_) {
      throw Exception('تعذر تحديث حالة المقعد');
    }
  }

  @override
  Future<OperationTrip> createTrip(CreateTripInput input) async {
    try {
      return await _datasource.createTrip(input);
    } catch (_) {
      throw Exception(
        'تعذر إنشاء الرحلة. المسار والسائق والمركبة والسعة مطلوبة',
      );
    }
  }

  @override
  Future<OperationTrip> updateTripInfo(OperationTrip trip) async {
    try {
      return await _datasource.updateTripInfo(trip);
    } catch (_) {
      throw Exception('تعذر تعديل بيانات الرحلة');
    }
  }

  @override
  Future<OperationTrip> updatePassenger(
    String tripId,
    TripPassenger passenger,
  ) async {
    try {
      return await _datasource.updatePassenger(tripId, passenger);
    } catch (_) {
      throw Exception('تعذر تعديل بيانات الراكب');
    }
  }

  @override
  Future<OperationTrip> cancelPassenger(
    String tripId,
    String passengerId,
  ) async {
    try {
      return await _datasource.cancelPassenger(tripId, passengerId);
    } catch (_) {
      throw Exception('تعذر إلغاء الحجز');
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
    } catch (_) {
      throw Exception('تعذر نقل الراكب. اختر مقعداً متاحاً');
    }
  }

  @override
  Future<List<TripPricing>> getTripPricing(String tripId) async {
    try {
      return await _datasource.fetchTripPricing(tripId);
    } catch (_) {
      throw Exception('تعذر تحميل تسعير الرحلة');
    }
  }

  @override
  Future<TripPricing> upsertTripPricing(TripPricing pricing) async {
    try {
      return await _datasource.upsertTripPricing(pricing);
    } catch (_) {
      throw Exception(
        'تعذر حفظ التسعير. تأكد من ترتيب النقاط وأن كل الأسعار أكبر من صفر',
      );
    }
  }

  @override
  Future<TripPricing> toggleTripPricingStatus(
    String pricingId,
    bool isActive,
  ) async {
    try {
      return await _datasource.toggleTripPricingStatus(pricingId, isActive);
    } catch (_) {
      throw Exception('تعذر تحديث حالة التسعير');
    }
  }
}
