import '../../domain/entities/dashboard_home_summary.dart';

sealed class DashboardHomeState {
  const DashboardHomeState();
}

class DashboardHomeLoading extends DashboardHomeState {
  const DashboardHomeLoading();
}

class DashboardHomeLoaded extends DashboardHomeState {
  final DashboardHomeSummary summary;

  const DashboardHomeLoaded(this.summary);
}

class DashboardHomeError extends DashboardHomeState {
  final String message;

  const DashboardHomeError(this.message);
}
