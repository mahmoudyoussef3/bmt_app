import '../../domain/entities/fleet_workspace.dart';

sealed class FleetState {
  const FleetState();
}

class FleetLoading extends FleetState {
  const FleetLoading();
}

class FleetError extends FleetState {
  final String message;

  const FleetError(this.message);
}

class FleetLoaded extends FleetState {
  final FleetWorkspace workspace;
  final FleetTab tab;
  final String searchQuery;
  final String filter;
  final FleetSortField sortField;
  final bool sortAscending;
  final int page;
  final int pageSize;
  final Set<String> selectedIds;

  const FleetLoaded({
    required this.workspace,
    this.tab = FleetTab.drivers,
    this.searchQuery = '',
    this.filter = 'الكل',
    this.sortField = FleetSortField.name,
    this.sortAscending = true,
    this.page = 0,
    this.pageSize = 8,
    this.selectedIds = const {},
  });

  FleetLoaded copyWith({
    FleetWorkspace? workspace,
    FleetTab? tab,
    String? searchQuery,
    String? filter,
    FleetSortField? sortField,
    bool? sortAscending,
    int? page,
    int? pageSize,
    Set<String>? selectedIds,
  }) {
    return FleetLoaded(
      workspace: workspace ?? this.workspace,
      tab: tab ?? this.tab,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}
