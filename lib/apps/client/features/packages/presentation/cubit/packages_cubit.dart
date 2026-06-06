import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/package_plan.dart';
import '../../domain/usecases/calculate_package_pricing_usecase.dart';
import '../../domain/usecases/filter_packages_usecase.dart';
import '../../domain/usecases/get_package_selection_data_usecase.dart';
import 'packages_state.dart';

class PackagesCubit extends Cubit<PackagesState> {
  PackagesCubit({
    required GetPackageSelectionDataUseCase getSelectionData,
    required FilterPackagesUseCase filterPackages,
    required CalculatePackagePricingUseCase calculatePricing,
  }) : _getSelectionData = getSelectionData,
       _filterPackages = filterPackages,
       _calculatePricing = calculatePricing,
       super(const PackagesLoading());

  final GetPackageSelectionDataUseCase _getSelectionData;
  final FilterPackagesUseCase _filterPackages;
  final CalculatePackagePricingUseCase _calculatePricing;

  Future<void> load() async {
    emit(const PackagesLoading());
    try {
      final data = await _getSelectionData();
      emit(
        PackagesLoaded(
          data: data,
          filteredPackages: _filterPackages(
            packages: data.packages,
            filter: 'All',
          ),
          pricing: _calculatePricing(
            package: null,
            vehicleAddonFee: data.vehicles.first.extraFee,
            selectedSeatCount: 0,
          ),
        ),
      );
    } catch (error) {
      emit(PackagesError(error.toString()));
    }
  }

  void selectFilter(String filter) {
    final current = state;
    if (current is! PackagesLoaded) return;
    emit(
      current.copyWith(
        selectedCategoryFilter: filter,
        filteredPackages: _filterPackages(
          packages: current.data.packages,
          filter: filter,
        ),
      ),
    );
  }

  void selectPackage(PackagePlan package) {
    final current = state;
    if (current is! PackagesLoaded) return;
    final selectedSeats = <int>{5};
    emit(
      current.copyWith(
        selectedPackage: package,
        selectedSeats: selectedSeats,
        pricing: _pricingFor(
          current,
          package: package,
          selectedSeatCount: selectedSeats.length,
        ),
      ),
    );
  }

  void selectRoute(String route) => _updateSelection(selectedRoute: route);

  void selectPickup(String pickup) => _updateSelection(selectedPickup: pickup);

  void selectDestination(String destination) {
    _updateSelection(selectedDestination: destination);
  }

  void selectVehicle(int index) {
    final current = state;
    if (current is! PackagesLoaded) return;
    emit(
      current.copyWith(
        selectedVehicleIndex: index,
        pricing: _pricingFor(current, selectedVehicleIndex: index),
      ),
    );
  }

  void toggleSeat(int seatNo) {
    final current = state;
    if (current is! PackagesLoaded) return;
    if (current.data.occupiedSeats.contains(seatNo)) return;

    final selectedSeats = Set<int>.from(current.selectedSeats);
    if (selectedSeats.contains(seatNo)) {
      selectedSeats.remove(seatNo);
    } else {
      selectedSeats.add(seatNo);
    }

    emit(
      current.copyWith(
        selectedSeats: selectedSeats,
        pricing: _pricingFor(current, selectedSeatCount: selectedSeats.length),
      ),
    );
  }

  void setAgreeTerms(bool value) {
    final current = state;
    if (current is! PackagesLoaded) return;
    emit(current.copyWith(agreeTerms: value));
  }

  void setProcessing(bool value) {
    final current = state;
    if (current is! PackagesLoaded) return;
    emit(current.copyWith(isProcessing: value));
  }

  void _updateSelection({
    String? selectedRoute,
    String? selectedPickup,
    String? selectedDestination,
  }) {
    final current = state;
    if (current is! PackagesLoaded) return;
    emit(
      current.copyWith(
        selectedRoute: selectedRoute,
        selectedPickup: selectedPickup,
        selectedDestination: selectedDestination,
      ),
    );
  }

  PackagePricing _pricingFor(
    PackagesLoaded current, {
    PackagePlan? package,
    int? selectedVehicleIndex,
    int? selectedSeatCount,
  }) {
    final vehicle = current
        .data
        .vehicles[selectedVehicleIndex ?? current.selectedVehicleIndex];
    return _calculatePricing(
      package: package ?? current.selectedPackage,
      vehicleAddonFee: vehicle.extraFee,
      selectedSeatCount: selectedSeatCount ?? current.selectedSeats.length,
    );
  }
}
