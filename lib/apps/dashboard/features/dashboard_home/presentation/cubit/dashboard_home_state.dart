import '../../domain/entities/dashboard_home_data.dart';

sealed class DashboardHomeState {
  const DashboardHomeState();
}

class DashboardHomeLoading extends DashboardHomeState {
  const DashboardHomeLoading();
}

class DashboardHomeLoaded extends DashboardHomeState {
  final DashboardHomeData data;

  const DashboardHomeLoaded(this.data);
}

class DashboardHomeError extends DashboardHomeState {
  final String message;

  const DashboardHomeError(this.message);
}
