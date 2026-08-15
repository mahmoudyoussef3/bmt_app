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
  }) : _getReportData = getReportData,
       _exportReport = exportReport,
       _getAvailableRoutes = getAvailableRoutes,
       _getAvailableDrivers = getAvailableDrivers,
       _getAvailableVehicles = getAvailableVehicles,
       _getAvailablePackages = getAvailablePackages,
       super(const ReportsLoading());

  /// The report the module opens on.
  ///
  /// Was [ReportType.trips] while trips returned a single KPI reading
  /// "قيد التطوير الفعلي" — so the first thing anyone saw of the reports module
  /// was a placeholder. Both work now; revenue leads because it is the question
  /// the module is opened to answer.
  static const defaultReportType = ReportType.revenue;

  Future<void> load() async {
    emit(const ReportsLoading());
    try {
      final results = await Future.wait([
        _getAvailableRoutes(),
        _getAvailableDrivers(),
        _getAvailableVehicles(),
        _getAvailablePackages(),
      ]);

      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 30));
      final defaultFilter = ReportFilter(startDate: start, endDate: end);

      final reportData = await _getReportData(defaultReportType, defaultFilter);

      if (isClosed) return;
      emit(
        ReportsLoaded(
          activeReportType: defaultReportType,
          filter: defaultFilter,
          reportData: reportData,
          availableRoutes: results[0],
          availableDrivers: results[1],
          availableVehicles: results[2],
          availablePackages: results[3],
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(ReportsError(error.toString()));
    }
  }

  Future<void> switchReportType(ReportType type) {
    final current = state;
    if (current is! ReportsLoaded) return Future.value();
    return _refetch(current.copyWith(activeReportType: type));
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
  }) {
    final current = state;
    if (current is! ReportsLoaded) return Future.value();

    return _refetch(
      current.copyWith(
        filter: current.filter.copyWith(
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
        ),
      ),
    );
  }

  Future<void> clearFilters() {
    final current = state;
    if (current is! ReportsLoaded) return Future.value();

    final end = DateTime.now();
    return _refetch(
      current.copyWith(
        filter: ReportFilter(
          startDate: end.subtract(const Duration(days: 30)),
          endDate: end,
        ),
      ),
    );
  }

  /// Refetches [next]'s report **over** the screen the operator is reading.
  ///
  /// The selection is applied immediately so the control the operator just
  /// touched shows what they chose, the table dims via `isRefreshing`, and a
  /// failure lands as a notice on the still-valid page rather than replacing it
  /// with a full-screen error that discards the filters they built.
  Future<void> _refetch(ReportsLoaded next) async {
    emit(
      next.copyWith(
        isRefreshing: true,
        clearActionError: true,
        clearExportingFormat: true,
        clearExportedFileName: true,
      ),
    );

    try {
      final reportData = await _getReportData(
        next.activeReportType,
        next.filter,
      );
      if (isClosed) return;
      emit(next.copyWith(reportData: reportData, isRefreshing: false));
    } catch (error) {
      if (isClosed) return;
      emit(
        next.copyWith(
          isRefreshing: false,
          actionError: 'تعذّر تحديث التقرير: $error',
        ),
      );
    }
  }

  Future<void> triggerExport(String format) async {
    final current = state;
    if (current is! ReportsLoaded) return;

    emit(current.copyWith(actionLoading: true, clearActionError: true));
    try {
      final fileName = await _exportReport(
        current.activeReportType,
        current.filter,
        format,
      );
      if (isClosed) return;
      emit(
        current.copyWith(
          actionLoading: false,
          exportingFormat: format,
          exportedFileName: fileName,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      // Swallowing this is how an operator ends up clicking "PDF" four times
      // and never learning the office is not licensed to export.
      emit(
        current.copyWith(
          actionLoading: false,
          actionError: 'تعذّر تصدير التقرير: $error',
        ),
      );
    }
  }

  void clearExport() {
    final current = state;
    if (current is! ReportsLoaded) return;
    emit(
      current.copyWith(clearExportingFormat: true, clearExportedFileName: true),
    );
  }

  void clearActionError() {
    final current = state;
    if (current is! ReportsLoaded) return;
    emit(current.copyWith(clearActionError: true));
  }
}
