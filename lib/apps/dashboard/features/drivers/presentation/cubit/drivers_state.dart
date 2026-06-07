import '../../domain/entities/driver.dart';
import '../models/driver_list_query.dart';

enum DriversView { list, details, create, edit, archive }

sealed class DriversState {
  const DriversState();
}

class DriversLoading extends DriversState {
  const DriversLoading();
}

class DriversError extends DriversState {
  final String message;

  const DriversError(this.message);
}

class DriversLoaded extends DriversState {
  final List<Driver> drivers;
  final DriverListQuery query;
  final DriversView view;
  final Driver? selectedDriver;

  const DriversLoaded({
    required this.drivers,
    required this.query,
    this.view = DriversView.list,
    this.selectedDriver,
  });

  List<Driver> get activeDrivers {
    return drivers
        .where((driver) => driver.status != DriverStatus.suspended)
        .toList();
  }

  List<Driver> get inactiveDrivers {
    return drivers
        .where((driver) => driver.status == DriverStatus.suspended)
        .toList();
  }

  List<Driver> get filteredDrivers {
    final source = view == DriversView.archive
        ? inactiveDrivers
        : activeDrivers;
    final search = query.search.trim().toLowerCase();
    final filtered = source.where((driver) {
      final statusMatch = query.status == null || driver.status == query.status;
      final text = [
        driver.name,
        driver.phone,
        driver.nationalId,
        driver.currentVehicle,
        driver.currentRoute,
        driver.status.label,
      ].join(' ').toLowerCase();
      final searchMatch = search.isEmpty || text.contains(search);
      return statusMatch && searchMatch;
    }).toList();

    filtered.sort((first, second) {
      final result = switch (query.sortBy) {
        DriverSortBy.name => first.name.compareTo(second.name),
        DriverSortBy.trips => first.totalTrips.compareTo(second.totalTrips),
        DriverSortBy.rating => first.rating.compareTo(second.rating),
        DriverSortBy.status => first.status.label.compareTo(
          second.status.label,
        ),
      };
      return query.ascending ? result : -result;
    });
    return filtered;
  }

  List<Driver> get pagedDrivers {
    return filteredDrivers
        .skip(query.page * query.pageSize)
        .take(query.pageSize)
        .toList();
  }

  int get maxPage {
    if (filteredDrivers.isEmpty) return 0;
    return ((filteredDrivers.length - 1) / query.pageSize).floor();
  }

  DriversLoaded copyWith({
    List<Driver>? drivers,
    DriverListQuery? query,
    DriversView? view,
    Driver? selectedDriver,
    bool clearSelectedDriver = false,
  }) {
    return DriversLoaded(
      drivers: drivers ?? this.drivers,
      query: query ?? this.query,
      view: view ?? this.view,
      selectedDriver: clearSelectedDriver
          ? null
          : selectedDriver ?? this.selectedDriver,
    );
  }
}
