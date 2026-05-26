part of 'admin_dashboard_cubit.dart';

class AdminDashboardState {
  final DashboardStats? stats;
  final List<Vehicle> vehicles;
  final List<Trip> activeTrips;
  final String selectedFilter;
  final bool isLoading;

  const AdminDashboardState({
    this.stats,
    this.vehicles = const [],
    this.activeTrips = const [],
    this.selectedFilter = 'all',
    this.isLoading = false,
  });

  AdminDashboardState copyWith({
    DashboardStats? stats,
    List<Vehicle>? vehicles,
    List<Trip>? activeTrips,
    String? selectedFilter,
    bool? isLoading,
  }) {
    return AdminDashboardState(
      stats: stats ?? this.stats,
      vehicles: vehicles ?? this.vehicles,
      activeTrips: activeTrips ?? this.activeTrips,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
