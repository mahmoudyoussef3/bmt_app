import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_lifecycle.dart';
import '../../../shared/domain/entities/trip_pricing.dart';
import '../../../trip_creation/domain/entities/trip_driver_option.dart';
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
    OperationTripStatus status, {
    String? reason,
  }) async {
    try {
      final trip = await _datasource.fetchTripById(tripId);
      if (trip.status == status) {
        return trip;
      }
      if (!TripLifecycle.canTransition(trip.status, status)) {
        throw Exception(
          'لا يمكن نقل الرحلة من "${trip.status.label}" إلى "${status.label}". استخدم الخطوة التشغيلية التالية فقط.',
        );
      }
      // Explained before the round trip so the operator gets an instruction rather
      // than a refusal. The server runs the same gate regardless.
      if (status == OperationTripStatus.openForBooking) {
        final blocker = TripPublishBlocker.evaluate(trip);
        if (blocker != null) {
          throw Exception('تعذر فتح الحجز: ${blocker.message}');
        }
      }
      if (status == OperationTripStatus.cancelled) {
        return await cancelTrip(tripId, reason ?? '');
      }
      return await _datasource.updateTripStatus(tripId, status, reason: reason);
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('تعذر تحديث حالة الرحلة: ${e.toString()}');
    }
  }

  @override
  Future<OperationTrip> cancelTrip(String tripId, String reason) async {
    try {
      final trimmed = reason.trim();
      if (trimmed.isEmpty) {
        throw Exception('يجب تحديد سبب إلغاء الرحلة.');
      }
      return await _datasource.cancelTrip(tripId, trimmed);
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('تعذر إلغاء الرحلة: ${e.toString()}');
    }
  }

  @override
  Future<OperationTrip> closeStaleTrip(
    String tripId,
    StaleTripOutcome outcome, {
    String? reason,
  }) async {
    try {
      return await _datasource.closeStaleTrip(
        tripId,
        outcome,
        reason: reason?.trim().isEmpty ?? true ? null : reason!.trim(),
      );
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('تعذر إغلاق الرحلة: ${e.toString()}');
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
      if (input.date.trim().isEmpty) {
        throw Exception('تاريخ الرحلة مطلوب.');
      }
      if (input.departure.trim().isEmpty) {
        throw Exception('وقت الانطلاق مطلوب.');
      }
      if (input.arrival.trim().isEmpty) {
        throw Exception('وقت الوصول مطلوب.');
      }
      if (input.ticketPrice <= 0) {
        throw Exception('سعر التذكرة مطلوب ويجب أن يكون أكبر من صفر.');
      }

      // 2. Cannot create trip with archived route.
      //    Kept client-side because it is the one rule the server does not run:
      //    office_create_trip checks the route's office, not its lifecycle.
      final routeStatus = await _datasource.getRouteStatus(input.routeId);
      if (routeStatus == 'archived') {
        throw Exception('لا يمكن جدولة رحلة لمسار مؤرشف.');
      }

      // 3. The driver must actually have a bus, and it must be in service.
      //
      //    Re-read here rather than trusted from the form: the planner can sit open
      //    while another operator reassigns the fleet. The server refuses the same
      //    cases (`driver_has_no_vehicle`, `vehicle_unavailable`) and is the authority;
      //    this exists so the operator is told which driver to fix and can be sent to
      //    the assignment screen, instead of reading a database error.
      //
      //    Driver *availability* (overlapping trips) is deliberately not pre-checked
      //    here any more. It used to be two queries comparing an exact date + departure
      //    time, which stopped matching reality when the fleet-authority migration
      //    replaced same-instant duplicates with service-window overlap. The wizard
      //    pre-filters busy drivers from `getResourceConflicts`, which mirrors the
      //    exclusion constraints exactly, and the server has the final word.
      final assignment = await _datasource.fetchDriverAssignment(
        input.driverId,
      );
      if (assignment == null) {
        throw Exception('السائق المختار لا يتبع مكتبك. أعد تحميل الصفحة.');
      }
      final vehicle = assignment.assignedVehicle;
      if (vehicle == null) {
        throw Exception(
          'هذا السائق غير مرتبط بسيارة حالياً. عيّن له سيارة من إدارة الأسطول أولاً.',
        );
      }
      if (!vehicle.isSchedulable) {
        throw Exception(
          'السيارة المخصصة للسائق (${vehicle.plateNumber}) غير متاحة للتشغيل حالياً. '
          'أعدها إلى حالة "نشطة" من إدارة الأسطول أو عيّن للسائق سيارة أخرى.',
        );
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
  Future<void> deleteTrip(String tripId) async {
    try {
      // Deleting a trip that carries bookings used to leave paid bookings pointing at
      // nothing — operation_bookings.trip_id is ON DELETE SET NULL — with no refund
      // trail and no word to the rider. Checked here so the operator is told to cancel
      // instead; `trg_enforce_trip_delete_guard` refuses it regardless.
      final trip = await _datasource.fetchTripById(tripId);
      if (!TripLifecycle.canDelete(trip)) {
        throw Exception(
          trip.passengers.isNotEmpty
              ? 'لا يمكن حذف رحلة عليها ركاب — ألغِها بدلاً من ذلك ليتم إشعارهم وتحرير المقاعد.'
              : 'لا يمكن حذف رحلة تم نشرها — ألغِها بدلاً من ذلك.',
        );
      }
      await _datasource.deleteTrip(tripId);
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('تعذر حذف الرحلة: ${e.toString()}');
    }
  }

  @override
  Future<OperationTrip> updateTripInfo(OperationTrip trip) async {
    try {
      if (trip.driverId.trim().isEmpty ||
          trip.date.trim().isEmpty ||
          trip.departure.trim().isEmpty) {
        throw Exception('البيانات الأساسية للرحلة مطلوبة.');
      }

      final current = await _datasource.fetchTripById(trip.id);

      // Changing the driver changes the bus with them — the pairing is what dispatch
      // means, and the server refuses a trip whose driver and vehicle contradict it.
      //
      // Leaving the driver alone leaves the vehicle *exactly* as recorded, even if that
      // driver has since been reassigned. The trip's vehicle is a snapshot of who was
      // paired with whom on the day it was created; re-deriving it on every save would
      // quietly rewrite which bus carried which passengers.
      final OperationTrip outgoing;
      if (trip.driverId == current.driverId) {
        outgoing = trip.copyWith(
          vehicleId: current.vehicleId,
          vehicle: current.vehicle,
        );
      } else {
        final assignment = await _datasource.fetchDriverAssignment(
          trip.driverId,
        );
        if (assignment == null) {
          throw Exception('السائق الجديد لا يتبع مكتبك.');
        }
        final vehicle = assignment.assignedVehicle;
        if (vehicle == null) {
          throw Exception(
            'السائق الجديد غير مرتبط بسيارة حالياً. عيّن له سيارة من إدارة الأسطول أولاً.',
          );
        }
        if (!vehicle.isSchedulable) {
          throw Exception(
            'السيارة المخصصة للسائق الجديد (${vehicle.plateNumber}) غير متاحة للتشغيل.',
          );
        }
        outgoing = trip.copyWith(
          vehicleId: vehicle.id,
          vehicle: vehicle.plateNumber,
        );
      }

      return await _datasource.updateTripInfo(outgoing);
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
        throw Exception(
          'نقطة البداية يجب أن تسبق نقطة النهاية في خط سير المسار.',
        );
      }
      if (pricing.oneTimePrice <= 0 || pricing.currency.trim().isEmpty) {
        throw Exception('يجب أن يكون سعر التذكرة والعملة صالحين.');
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
  Future<List<TripDriverOption>> getActiveDrivers() {
    return _datasource.fetchActiveDrivers();
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveRoutes() {
    return _datasource.fetchActiveRoutes();
  }

  @override
  Future<List<Map<String, dynamic>>> getResourceConflicts({
    required String date,
    required String departureTime,
    required String arrivalTime,
  }) {
    return _datasource.fetchResourceConflicts(
      date: date,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
    );
  }

  @override
  Stream<void> watchTripsChanges() => _datasource.watchTripsChanges();

  @override
  Stream<void> watchTripChanges(String tripId) =>
      _datasource.watchTripChanges(tripId);
}
