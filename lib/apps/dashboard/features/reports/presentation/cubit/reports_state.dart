import '../../domain/entities/report_entities.dart';

sealed class ReportsState {
  const ReportsState();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

class ReportsError extends ReportsState {
  final String message;
  const ReportsError(this.message);
}

class ReportsLoaded extends ReportsState {
  final ReportType activeReportType;
  final ReportFilter filter;
  final ReportData reportData;

  final List<String> availableRoutes;
  final List<String> availableDrivers;
  final List<String> availableVehicles;
  final List<String> availablePackages;

  final String? exportingFormat; // pdf, excel, csv
  final String? exportedFileName;
  final bool actionLoading;

  const ReportsLoaded({
    required this.activeReportType,
    required this.filter,
    required this.reportData,
    required this.availableRoutes,
    required this.availableDrivers,
    required this.availableVehicles,
    required this.availablePackages,
    this.exportingFormat,
    this.exportedFileName,
    this.actionLoading = false,
  });

  ReportsLoaded copyWith({
    ReportType? activeReportType,
    ReportFilter? filter,
    ReportData? reportData,
    List<String>? availableRoutes,
    List<String>? availableDrivers,
    List<String>? availableVehicles,
    List<String>? availablePackages,
    String? exportingFormat,
    bool clearExportingFormat = false,
    String? exportedFileName,
    bool clearExportedFileName = false,
    bool? actionLoading,
  }) {
    return ReportsLoaded(
      activeReportType: activeReportType ?? this.activeReportType,
      filter: filter ?? this.filter,
      reportData: reportData ?? this.reportData,
      availableRoutes: availableRoutes ?? this.availableRoutes,
      availableDrivers: availableDrivers ?? this.availableDrivers,
      availableVehicles: availableVehicles ?? this.availableVehicles,
      availablePackages: availablePackages ?? this.availablePackages,
      exportingFormat: clearExportingFormat
          ? null
          : (exportingFormat ?? this.exportingFormat),
      exportedFileName: clearExportedFileName
          ? null
          : (exportedFileName ?? this.exportedFileName),
      actionLoading: actionLoading ?? this.actionLoading,
    );
  }
}
