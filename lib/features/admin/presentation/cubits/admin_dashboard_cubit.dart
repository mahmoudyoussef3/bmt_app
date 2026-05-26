import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/shared/models/models.dart';
import 'package:bmt_app/shared/mock_data/mock_data.dart';

part 'admin_dashboard_state.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit() : super(const AdminDashboardState()) {
    loadDashboard();
  }

  void loadDashboard() {
    final stats = MockData.dashboardStats;
    final vehicles = MockData.vehicles;
    final trips = MockData.getUpcomingTrips();

    emit(
      AdminDashboardState(stats: stats, vehicles: vehicles, activeTrips: trips),
    );
  }

  void filterByStatus(String status) {
    emit(state.copyWith(selectedFilter: status));
  }
}
