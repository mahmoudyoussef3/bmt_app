import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_pricing.dart';
import '../../domain/usecases/trip_creation_usecases.dart';

sealed class TripCreationState {
  const TripCreationState();
}

class TripCreationInitial extends TripCreationState {
  const TripCreationInitial();
}

class TripCreationLoading extends TripCreationState {
  const TripCreationLoading();
}

class TripCreationError extends TripCreationState {
  final String message;
  const TripCreationError(this.message);
}

class TripCreationWizardDataLoaded extends TripCreationState {
  final List<Map<String, dynamic>> routes;
  final List<Map<String, dynamic>> drivers;
  final List<Map<String, dynamic>> vehicles;

  const TripCreationWizardDataLoaded({
    required this.routes,
    required this.drivers,
    required this.vehicles,
  });
}

class TripCreationSuccess extends TripCreationState {
  final OperationTrip trip;
  const TripCreationSuccess(this.trip);
}

class TripCreationCubit extends Cubit<TripCreationState> {
  final CreateTripUseCase _createTrip;
  final GetActiveRoutesUseCase _getActiveRoutes;
  final GetActiveDriversUseCase _getActiveDrivers;
  final GetActiveVehiclesUseCase _getActiveVehicles;

  TripCreationCubit({
    required CreateTripUseCase createTrip,
    required GetActiveRoutesUseCase getActiveRoutes,
    required GetActiveDriversUseCase getActiveDrivers,
    required GetActiveVehiclesUseCase getActiveVehicles,
  }) : _createTrip = createTrip,
       _getActiveRoutes = getActiveRoutes,
       _getActiveDrivers = getActiveDrivers,
       _getActiveVehicles = getActiveVehicles,
       super(const TripCreationInitial());

  Future<void> loadWizardData() async {
    emit(const TripCreationLoading());
    try {
      final routes = await _getActiveRoutes();
      final drivers = await _getActiveDrivers();
      final vehicles = await _getActiveVehicles();
      emit(
        TripCreationWizardDataLoaded(
          routes: routes,
          drivers: drivers,
          vehicles: vehicles,
        ),
      );
    } catch (e) {
      emit(TripCreationError(e.toString()));
    }
  }

  Future<OperationTrip?> submitTrip(
    CreateTripInput input,
    List<TripPricing> pricing,
  ) async {
    final prev = state;
    emit(const TripCreationLoading());
    try {
      final trip = await _createTrip(input, pricing);
      emit(TripCreationSuccess(trip));
      return trip;
    } catch (e) {
      emit(TripCreationError(_friendlyError(e.toString())));
      if (prev is TripCreationWizardDataLoaded) emit(prev);
      return null;
    }
  }

  void reset() {
    emit(const TripCreationInitial());
  }

  /// Turns a database rejection into a sentence that tells the operator what to do
  /// about it.
  ///
  /// The fleet-authority migration replaced the old whole-day resource lock with a
  /// service-window overlap rule and added availability, capacity and seat-layout
  /// gates, so these are the refusals trip creation can now actually receive. The
  /// exclusion-constraint names appear when a conflicting write reaches the table
  /// without going through `create_trip`.
  static String _friendlyError(String raw) {
    if (raw.contains('driver_conflict') ||
        raw.contains('operation_trips_driver_no_overlap')) {
      return 'السائق لديه رحلة أخرى تتداخل مع هذا التوقيت (مع احتساب 30 دقيقة '
          'للاستعداد بين الرحلات). اختر سائقاً آخر أو غيّر التوقيت.';
    }
    if (raw.contains('vehicle_conflict') ||
        raw.contains('operation_trips_vehicle_no_overlap')) {
      return 'المركبة مرتبطة برحلة أخرى تتداخل مع هذا التوقيت (مع احتساب 30 دقيقة '
          'للاستعداد بين الرحلات). اختر مركبة أخرى أو غيّر التوقيت.';
    }
    if (raw.contains('vehicle_unavailable')) {
      return 'المركبة غير متاحة للتشغيل حالياً (صيانة أو موقوفة أو مؤرشفة). '
          'أعدها إلى حالة "نشطة" من إدارة الأسطول أولاً.';
    }
    if (raw.contains('driver_unavailable')) {
      return 'السائق غير متاح للتشغيل حالياً (موقوف أو مؤرشف). '
          'أعده إلى حالة "نشط" من إدارة الأسطول أولاً.';
    }
    if (raw.contains('vehicle_has_no_seats')) {
      return 'المركبة المختارة ليس لها تخطيط مقاعد محفوظ. افتحها في إدارة الأسطول '
          'واحفظ تخطيط مقاعدها قبل جدولة رحلة عليها.';
    }
    if (raw.contains('capacity_mismatch')) {
      return 'عدد مقاعد المركبة تغيّر منذ فتح هذه الشاشة. أعد تحميل قائمة المركبات '
          'ثم أنشئ الرحلة من جديد.';
    }
    if (raw.contains('duplicate_seat_labels')) {
      return 'تخطيط مقاعد المركبة يحتوي على أرقام مقاعد مكررة. صحّح التخطيط في '
          'إدارة الأسطول أولاً.';
    }
    if (raw.contains('vehicle_not_in_office') ||
        raw.contains('driver_not_in_office') ||
        raw.contains('route_not_in_office')) {
      return 'أحد العناصر المختارة لا يتبع مكتبك. أعد تحميل الصفحة وحاول مجدداً.';
    }
    return raw;
  }
}
