import 'package:bmt_app/apps/dashboard/modules/fleet/shared/domain/entities/fleet_driver.dart';

sealed class FleetDriversState {
  const FleetDriversState();
}

class FleetDriversLoading extends FleetDriversState {
  const FleetDriversLoading();
}

class FleetDriversError extends FleetDriversState {
  final String message;
  const FleetDriversError(this.message);
}

class FleetDriversLoaded extends FleetDriversState {
  final List<FleetDriver> drivers;
  final String searchQuery;
  final String filter;
  final Set<String> selectedIds;

  const FleetDriversLoaded({
    required this.drivers,
    this.searchQuery = '',
    this.filter = 'الكل',
    this.selectedIds = const {},
  });

  FleetDriversLoaded copyWith({
    List<FleetDriver>? drivers,
    String? searchQuery,
    String? filter,
    Set<String>? selectedIds,
  }) {
    return FleetDriversLoaded(
      drivers: drivers ?? this.drivers,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }

  /// Filtered + searched drivers for display.
  List<FleetDriver> get filteredDrivers {
    var result = drivers;
    if (filter != 'الكل') {
      result = result.where((d) => d.status.label == filter).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where(
            (d) =>
                d.fullName.toLowerCase().contains(q) ||
                d.employeeCode.toLowerCase().contains(q) ||
                d.phone.contains(q),
          )
          .toList();
    }
    return result;
  }
}
