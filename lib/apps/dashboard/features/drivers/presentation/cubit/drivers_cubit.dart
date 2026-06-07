import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/driver.dart';
import '../../domain/usecases/create_driver_usecase.dart';
import '../../domain/usecases/delete_driver_usecase.dart';
import '../../domain/usecases/get_drivers_usecase.dart';
import '../../domain/usecases/update_driver_status_usecase.dart';
import '../../domain/usecases/update_driver_usecase.dart';
import '../models/driver_list_query.dart';
import 'drivers_state.dart';

class DriversCubit extends Cubit<DriversState> {
  final GetDriversUseCase _getDrivers;
  final CreateDriverUseCase _createDriver;
  final UpdateDriverUseCase _updateDriver;
  final UpdateDriverStatusUseCase _updateDriverStatus;
  final DeleteDriverUseCase _deleteDriver;

  DriversCubit({
    required GetDriversUseCase getDrivers,
    required CreateDriverUseCase createDriver,
    required UpdateDriverUseCase updateDriver,
    required UpdateDriverStatusUseCase updateDriverStatus,
    required DeleteDriverUseCase deleteDriver,
  }) : _getDrivers = getDrivers,
       _createDriver = createDriver,
       _updateDriver = updateDriver,
       _updateDriverStatus = updateDriverStatus,
       _deleteDriver = deleteDriver,
       super(const DriversLoading());

  Future<void> load() async {
    emit(const DriversLoading());
    try {
      final drivers = await _getDrivers();
      emit(DriversLoaded(drivers: drivers, query: const DriverListQuery()));
    } catch (error) {
      emit(DriversError(error.toString()));
    }
  }

  void showList() {
    final current = state;
    if (current is! DriversLoaded) return;
    emit(
      current.copyWith(
        view: DriversView.list,
        query: current.query.copyWith(page: 0, clearStatus: true),
        clearSelectedDriver: true,
      ),
    );
  }

  void showArchive() {
    final current = state;
    if (current is! DriversLoaded) return;
    emit(
      current.copyWith(
        view: DriversView.archive,
        query: current.query.copyWith(page: 0, clearStatus: true),
        clearSelectedDriver: true,
      ),
    );
  }

  void showCreate() {
    final current = state;
    if (current is! DriversLoaded) return;
    emit(current.copyWith(view: DriversView.create, clearSelectedDriver: true));
  }

  void showDetails(Driver driver) {
    final current = state;
    if (current is! DriversLoaded) return;
    emit(current.copyWith(view: DriversView.details, selectedDriver: driver));
  }

  void showEdit(Driver driver) {
    final current = state;
    if (current is! DriversLoaded) return;
    emit(current.copyWith(view: DriversView.edit, selectedDriver: driver));
  }

  void updateSearch(String value) {
    final current = state;
    if (current is! DriversLoaded) return;
    emit(
      current.copyWith(query: current.query.copyWith(search: value, page: 0)),
    );
  }

  void updateStatusFilter(DriverStatus? status) {
    final current = state;
    if (current is! DriversLoaded) return;
    emit(
      current.copyWith(
        query: current.query.copyWith(
          status: status,
          clearStatus: status == null,
          page: 0,
        ),
      ),
    );
  }

  void updateSort(DriverSortBy sortBy) {
    final current = state;
    if (current is! DriversLoaded) return;
    final ascending = current.query.sortBy == sortBy
        ? !current.query.ascending
        : true;
    emit(
      current.copyWith(
        query: current.query.copyWith(
          sortBy: sortBy,
          ascending: ascending,
          page: 0,
        ),
      ),
    );
  }

  void updatePage(int page) {
    final current = state;
    if (current is! DriversLoaded) return;
    emit(current.copyWith(query: current.query.copyWith(page: page)));
  }

  Future<void> saveDriver(Driver driver) async {
    final current = state;
    if (current is! DriversLoaded) return;
    try {
      final saved = driver.id.isEmpty
          ? await _createDriver(driver)
          : await _updateDriver(driver);
      final withoutOld = current.drivers
          .where((item) => item.id != saved.id)
          .toList();
      emit(
        current.copyWith(
          drivers: [saved, ...withoutOld],
          view: DriversView.details,
          selectedDriver: saved,
        ),
      );
    } catch (error) {
      emit(DriversError(error.toString()));
    }
  }

  Future<void> updateDriverStatus(Driver driver, DriverStatus status) async {
    final current = state;
    if (current is! DriversLoaded) return;
    try {
      final updated = await _updateDriverStatus(driver.id, status);
      final drivers = current.drivers
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      emit(
        current.copyWith(
          drivers: drivers,
          selectedDriver: current.selectedDriver?.id == updated.id
              ? updated
              : current.selectedDriver,
        ),
      );
    } catch (error) {
      emit(DriversError(error.toString()));
    }
  }

  Future<void> deleteDriver(Driver driver) async {
    final current = state;
    if (current is! DriversLoaded) return;
    try {
      await _deleteDriver(driver.id);
      emit(
        current.copyWith(
          drivers: current.drivers
              .where((item) => item.id != driver.id)
              .toList(),
          view: DriversView.list,
          clearSelectedDriver: true,
        ),
      );
    } catch (error) {
      emit(DriversError(error.toString()));
    }
  }
}
