import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/reports/domain/entities/report_entities.dart';
import 'package:bmt_app/apps/dashboard/features/reports/domain/repositories/reports_repository.dart';
import 'package:bmt_app/apps/dashboard/features/reports/domain/usecases/export_report_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/reports/domain/usecases/get_available_drivers_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/reports/domain/usecases/get_available_packages_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/reports/domain/usecases/get_available_routes_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/reports/domain/usecases/get_available_vehicles_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/reports/domain/usecases/get_report_data_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/reports/presentation/cubit/reports_state.dart';

void main() {
  group('ReportsCubit Tests', () {
    late _MockReportsRepository repository;
    late ReportsCubit cubit;

    setUp(() {
      repository = _MockReportsRepository();
      cubit = ReportsCubit(
        getReportData: GetReportDataUseCase(repository),
        exportReport: ExportReportUseCase(repository),
        getAvailableRoutes: GetAvailableRoutesUseCase(repository),
        getAvailableDrivers: GetAvailableDriversUseCase(repository),
        getAvailableVehicles: GetAvailableVehiclesUseCase(repository),
        getAvailablePackages: GetAvailablePackagesUseCase(repository),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is ReportsLoading', () {
      expect(cubit.state, isA<ReportsLoading>());
    });

    test('load() success emits ReportsLoaded with data', () async {
      await cubit.load();
      expect(cubit.state, isA<ReportsLoaded>());
      final state = cubit.state as ReportsLoaded;
      expect(state.activeReportType, ReportType.trips);
      expect(state.availableRoutes, contains('ROUTE-1'));
      expect(state.availableDrivers, contains('DRIVER-1'));
      expect(state.availableVehicles, contains('VEHICLE-1'));
      expect(state.availablePackages, contains('PACKAGE-1'));
      expect(state.reportData.kpis, isNotEmpty);
    });

    test('switchReportType() switches and loads new report type', () async {
      await cubit.load();
      await cubit.switchReportType(ReportType.bookings);

      expect(cubit.state, isA<ReportsLoaded>());
      final state = cubit.state as ReportsLoaded;
      expect(state.activeReportType, ReportType.bookings);
      expect(state.reportData.kpis['type'], 'bookings');
    });

    test('updateFilter() updates filter values and reloads data', () async {
      await cubit.load();
      final newStart = DateTime(2026, 1, 1);
      final newEnd = DateTime(2026, 1, 31);

      await cubit.updateFilter(
        start: newStart,
        end: newEnd,
        route: 'ROUTE-2',
        driver: 'DRIVER-2',
        vehicle: 'VEHICLE-2',
        pkg: 'PACKAGE-2',
      );

      expect(cubit.state, isA<ReportsLoaded>());
      final state = cubit.state as ReportsLoaded;
      expect(state.filter.startDate, newStart);
      expect(state.filter.endDate, newEnd);
      expect(state.filter.routeCode, 'ROUTE-2');
      expect(state.filter.driverName, 'DRIVER-2');
      expect(state.filter.vehiclePlate, 'VEHICLE-2');
      expect(state.filter.packageName, 'PACKAGE-2');
    });

    test('clearFilters() clears dropdown filters and resets dates', () async {
      await cubit.load();
      // First update it with some filters
      await cubit.updateFilter(route: 'ROUTE-2', driver: 'DRIVER-2');
      var state = cubit.state as ReportsLoaded;
      expect(state.filter.routeCode, 'ROUTE-2');

      // Now clear them
      await cubit.clearFilters();
      state = cubit.state as ReportsLoaded;
      expect(state.filter.routeCode, isNull);
      expect(state.filter.driverName, isNull);
    });

    test(
      'triggerExport() sets exporting format and exported file name',
      () async {
        await cubit.load();
        await cubit.triggerExport('pdf');

        expect(cubit.state, isA<ReportsLoaded>());
        final state = cubit.state as ReportsLoaded;
        expect(state.exportingFormat, 'pdf');
        expect(state.exportedFileName, contains('.pdf'));
      },
    );

    test('clearExport() resets export variables', () async {
      await cubit.load();
      await cubit.triggerExport('excel');
      var state = cubit.state as ReportsLoaded;
      expect(state.exportingFormat, 'excel');

      cubit.clearExport();
      state = cubit.state as ReportsLoaded;
      expect(state.exportingFormat, isNull);
      expect(state.exportedFileName, isNull);
    });
  });
}

class _MockReportsRepository implements ReportsRepository {
  @override
  Future<ReportData> getReportData(ReportType type, ReportFilter filter) async {
    return ReportData(
      kpis: {'type': type.name, 'إجمالي': '100'},
      rows: const [],
      trends: const [],
    );
  }

  @override
  Future<String> exportReport(
    ReportType type,
    ReportFilter filter,
    String format,
  ) async {
    return 'report_${type.name}_export.$format';
  }

  @override
  Future<List<String>> getAvailableRoutes() async => ['ROUTE-1', 'ROUTE-2'];

  @override
  Future<List<String>> getAvailableDrivers() async => ['DRIVER-1', 'DRIVER-2'];

  @override
  Future<List<String>> getAvailableVehicles() async => [
    'VEHICLE-1',
    'VEHICLE-2',
  ];

  @override
  Future<List<String>> getAvailablePackages() async => [
    'PACKAGE-1',
    'PACKAGE-2',
  ];
}
