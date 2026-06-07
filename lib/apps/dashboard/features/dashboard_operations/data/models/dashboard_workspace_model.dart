import '../../domain/entities/dashboard_workspace.dart';

class DashboardWorkspaceModel extends DashboardWorkspace {
  const DashboardWorkspaceModel({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.actions,
    required super.metrics,
    required super.tabs,
    required super.columns,
    required super.rows,
    required super.sections,
    super.statusOptions,
  });
}
