import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/domain/entities/operation_trip.dart';
import '../../../shared/domain/entities/trip_package_offer.dart';
import '../../../shared/domain/entities/trip_pricable_package.dart';
import '../../../shared/domain/entities/trip_pricing.dart';
import '../../domain/entities/trip_driver_option.dart';
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

  /// Drivers with the vehicle each one operates. There is no separate vehicle list:
  /// the planner offers one resource choice and derives the bus from it.
  final List<TripDriverOption> drivers;

  /// The office's saved catalog packages, offered as a starting point in the
  /// fare panel — never the limit of what a trip may sell.
  final List<TripPricablePackage> packages;

  const TripCreationWizardDataLoaded({
    required this.routes,
    required this.drivers,
    required this.packages,
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
  final GetResourceConflictsUseCase _getResourceConflicts;
  final GetOfficePricablePackagesUseCase _getPricablePackages;

  TripCreationCubit({
    required CreateTripUseCase createTrip,
    required GetActiveRoutesUseCase getActiveRoutes,
    required GetActiveDriversUseCase getActiveDrivers,
    required GetResourceConflictsUseCase getResourceConflicts,
    required GetOfficePricablePackagesUseCase getPricablePackages,
  }) : _createTrip = createTrip,
       _getActiveRoutes = getActiveRoutes,
       _getActiveDrivers = getActiveDrivers,
       _getResourceConflicts = getResourceConflicts,
       _getPricablePackages = getPricablePackages,
       super(const TripCreationInitial());

  /// Three independent reads, issued together. Routes/drivers used to be
  /// three round trips on their own; the office's catalog packages — what the
  /// fare panel offers to add to the trip — join them here rather than the
  /// fare panel fetching separately.
  Future<void> loadWizardData() async {
    emit(const TripCreationLoading());
    try {
      final results = await Future.wait([
        _getActiveRoutes(),
        _getActiveDrivers(),
        _getPricablePackages(),
      ]);
      emit(
        TripCreationWizardDataLoaded(
          routes: results[0] as List<Map<String, dynamic>>,
          drivers: results[1] as List<TripDriverOption>,
          packages: results[2] as List<TripPricablePackage>,
        ),
      );
    } catch (e) {
      emit(TripCreationError(e.toString()));
    }
  }

  /// [offers] is the package menu the operator built for this trip. Any offer
  /// with no `packageId` is created against the new trip before it is priced,
  /// so an office can sell a package it never added to its catalog.
  Future<OperationTrip?> submitTrip(
    CreateTripInput input,
    List<TripPricing> pricing,
    List<TripPackageOffer> offers,
  ) async {
    final prev = state;
    emit(const TripCreationLoading());
    try {
      final trip = await _createTrip(input, pricing, offers);
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

  /// Rows of trips that already occupy part of the given time slot, keyed by
  /// `driver_id`/`vehicle_id`. Deliberately does NOT emit a state: it is called
  /// on every schedule tweak while the wizard form (routes/vehicles/drivers,
  /// current selections) stays on screen, and swapping the sealed state would
  /// tear that form down and lose the operator's in-progress picks.
  Future<List<Map<String, dynamic>>> getResourceConflicts({
    required String date,
    required String departureTime,
    required String arrivalTime,
  }) {
    return _getResourceConflicts(
      date: date,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
    );
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
    if (raw.contains('driver_has_no_vehicle')) {
      return 'هذا السائق غير مرتبط بسيارة حالياً. عيّن له سيارة من إدارة الأسطول '
          'ثم أعد المحاولة.';
    }
    if (raw.contains('driver_vehicle_mismatch')) {
      return 'تم تغيير السيارة المخصصة لهذا السائق منذ فتح هذه الشاشة. أعد تحميل '
          'قائمة السائقين ثم أنشئ الرحلة من جديد.';
    }
    if (raw.contains('driver_required')) {
      return 'يجب اختيار السائق قبل إنشاء الرحلة.';
    }
    if (raw.contains('driver_conflict') ||
        raw.contains('operation_trips_driver_no_overlap')) {
      return 'السائق والسيارة المخصصة له غير متاحين في هذا التوقيت — لديهما رحلة '
          'أخرى متداخلة (مع احتساب 30 دقيقة للاستعداد بين الرحلات). اختر سائقاً '
          'آخر أو غيّر التوقيت.';
    }
    if (raw.contains('vehicle_conflict') ||
        raw.contains('operation_trips_vehicle_no_overlap')) {
      return 'السيارة المخصصة لهذا السائق مرتبطة برحلة أخرى تتداخل مع هذا التوقيت '
          '(مع احتساب 30 دقيقة للاستعداد بين الرحلات). اختر سائقاً آخر أو غيّر '
          'التوقيت.';
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
    if (raw.contains('uq_operation_trips_office_trip_code') ||
        (raw.contains('duplicate key') && raw.contains('trip_code'))) {
      return 'حدث تعارض مؤقت أثناء ترقيم الرحلة. حاول إنشاء الرحلة مرة أخرى.';
    }
    return raw;
  }
}
