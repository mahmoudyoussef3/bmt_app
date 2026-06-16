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
      final msg = e.toString();
      final friendly = msg.contains('driver_conflict')
          ? 'السائق لديه رحلة مجدولة بالفعل في هذا اليوم. يرجى اختيار سائق آخر أو تاريخ مختلف.'
          : msg.contains('vehicle_conflict')
              ? 'المركبة مخصصة لرحلة أخرى في هذا اليوم. يرجى اختيار مركبة أخرى أو تاريخ مختلف.'
              : msg;
      emit(TripCreationError(friendly));
      if (prev is TripCreationWizardDataLoaded) emit(prev);
      return null;
    }
  }

  void reset() {
    emit(const TripCreationInitial());
  }
}
