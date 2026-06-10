import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/report_entities.dart';
import '../../domain/usecases/export_report_usecase.dart';
import '../../domain/usecases/get_available_drivers_usecase.dart';
import '../../domain/usecases/get_available_packages_usecase.dart';
import '../../domain/usecases/get_available_routes_usecase.dart';
import '../../domain/usecases/get_available_vehicles_usecase.dart';
import '../../domain/usecases/get_report_data_usecase.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final GetReportDataUseCase _getReportData;
  final ExportReportUseCase _exportReport;
  final GetAvailableRoutesUseCase _getAvailableRoutes;
  final GetAvailableDriversUseCase _getAvailableDrivers;
  final GetAvailableVehiclesUseCase _getAvailableVehicles;
  final GetAvailablePackagesUseCase _getAvailablePackages;

  ReportsCubit({
    required GetReportDataUseCase getReportData,
    required ExportReportUseCase exportReport,
    required GetAvailableRoutesUseCase getAvailableRoutes,
    required GetAvailableDriversUseCase getAvailableDrivers,
    required GetAvailableVehiclesUseCase getAvailableVehicles,
    required GetAvailablePackagesUseCase getAvailablePackages,
  })  : _getReportData = getReportData,
        _exportReport = exportReport,
        _getAvailableRoutes = getAvailableRoutes,
        _getAvailableDrivers = getAvailableDrivers,
        _getAvailableVehicles = getAvailableVehicles,
        _getAvailablePackages = getAvailablePackages,
        super(const ReportsLoading());

  Future<void> load() async {
    emit(const ReportsLoading());
    try {
      final routes = await _getAvailableRoutes();
      final drivers = await _getAvailableDrivers();
      final vehicles = await _getAvailableVehicles();
      final packages = await _getAvailablePackages();

      // Default date range: last 30 days
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 30));

      final defaultFilter = ReportFilter(
        startDate: start,
        endDate: end,
      );

      final reportData = await _getReportData(ReportType.trips, defaultFilter);

      emit(ReportsLoaded(
        activeReportType: ReportType.trips,
        filter: defaultFilter,
        reportData: reportData,
        availableRoutes: routes,
        availableDrivers: drivers,
        availableVehicles: vehicles,
        availablePackages: packages,
      ));
    } catch (error) {
      emit(ReportsError(error.toString()));
    }
  }

  Future<void> switchReportType(ReportType type) async {
    final current = state;
    if (current is! ReportsLoaded) return;

    emit(const ReportsLoading());
    try {
      final reportData = await _getReportData(type, current.filter);
      emit(current.copyWith(
        activeReportType: type,
        reportData: reportData,
        clearExportingFormat: true,
        clearExportedFileName: true,
      ));
    } catch (error) {
      emit(ReportsError(error.toString()));
    }
  }

  Future<void> updateFilter({
    DateTime? start,
    DateTime? end,
    String? route,
    bool clearRoute = false,
    String? driver,
    bool clearDriver = false,
    String? vehicle,
    bool clearVehicle = false,
    String? pkg,
    bool clearPackage = false,
  }) async {
    final current = state;
    if (current is! ReportsLoaded) return;

    final updatedFilter = current.filter.copyWith(
      startDate: start,
      endDate: end,
      routeCode: route,
      clearRoute: clearRoute,
      driverName: driver,
      clearDriver: clearDriver,
      vehiclePlate: vehicle,
      clearVehicle: clearVehicle,
      packageName: pkg,
      clearPackage: clearPackage,
    );

    emit(const ReportsLoading());
    try {
      final reportData = await _getReportData(current.activeReportType, updatedFilter);
      emit(current.copyWith(
        filter: updatedFilter,
        reportData: reportData,
      ));
    } catch (error) {
      emit(ReportsError(error.toString()));
    }
  }

  Future<void> clearFilters() async {
    final current = state;
    if (current is! ReportsLoaded) return;

    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 30));

    final clearedFilter = ReportFilter(
      startDate: start,
      endDate: end,
    );

    emit(const ReportsLoading());
    try {
      final reportData = await _getReportData(current.activeReportType, clearedFilter);
      emit(current.copyWith(
        filter: clearedFilter,
        reportData: reportData,
      ));
    } catch (error) {
      emit(ReportsError(error.toString()));
    }
  }

  Future<void> triggerExport(String format) async {
    final current = state;
    if (current is! ReportsLoaded) return;

    emit(current.copyWith(actionLoading: true));
    try {
      final fileName = await _exportReport(current.activeReportType, current.filter, format);
      emit(current.copyWith(
        actionLoading: false,
        exportingFormat: format,
        exportedFileName: fileName,
      ));
    } catch (error) {
      emit(current.copyWith(actionLoading: false));
    }
  }

  void clearExport() {
    final current = state;
    if (current is! ReportsLoaded) return;
    emit(current.copyWith(
      clearExportingFormat: true,
      clearExportedFileName: true,
    ));
  }
}
