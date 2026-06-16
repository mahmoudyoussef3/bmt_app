import '../../domain/entities/package_plan.dart';

sealed class PackagesState {
  const PackagesState();
}

class PackagesLoading extends PackagesState {
  const PackagesLoading();
}

class PackagesLoaded extends PackagesState {
  const PackagesLoaded({
    required this.data,
    required this.filteredPackages,
    required this.pricing,
    this.selectedCategoryFilter = 'All',
    this.selectedPackage,
    this.selectedRoute = '',
    this.selectedPickup = '',
    this.selectedDestination = '',
    this.selectedVehicleIndex = 0,
    this.selectedSeats = const {},
    this.agreeTerms = false,
    this.isProcessing = false,
  });

  final PackageSelectionData data;
  final List<PackagePlan> filteredPackages;
  final PackagePricing pricing;
  final String selectedCategoryFilter;
  final PackagePlan? selectedPackage;
  final String selectedRoute;
  final String selectedPickup;
  final String selectedDestination;
  final int selectedVehicleIndex;
  final Set<int> selectedSeats;
  final bool agreeTerms;
  final bool isProcessing;

  PackageVehicleType get selectedVehicle => data.vehicles[selectedVehicleIndex];

  PackagesLoaded copyWith({
    List<PackagePlan>? filteredPackages,
    PackagePricing? pricing,
    String? selectedCategoryFilter,
    PackagePlan? selectedPackage,
    String? selectedRoute,
    String? selectedPickup,
    String? selectedDestination,
    int? selectedVehicleIndex,
    Set<int>? selectedSeats,
    bool? agreeTerms,
    bool? isProcessing,
  }) {
    return PackagesLoaded(
      data: data,
      filteredPackages: filteredPackages ?? this.filteredPackages,
      pricing: pricing ?? this.pricing,
      selectedCategoryFilter:
          selectedCategoryFilter ?? this.selectedCategoryFilter,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      selectedPickup: selectedPickup ?? this.selectedPickup,
      selectedDestination: selectedDestination ?? this.selectedDestination,
      selectedVehicleIndex: selectedVehicleIndex ?? this.selectedVehicleIndex,
      selectedSeats: selectedSeats ?? this.selectedSeats,
      agreeTerms: agreeTerms ?? this.agreeTerms,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class PackagesError extends PackagesState {
  const PackagesError(this.message);

  final String message;
}
