import '../../domain/entities/office_summary.dart';

sealed class OfficesDirectoryState {
  const OfficesDirectoryState();
}

class OfficesDirectoryLoading extends OfficesDirectoryState {
  const OfficesDirectoryLoading();
}

class OfficesDirectoryLoaded extends OfficesDirectoryState {
  const OfficesDirectoryLoaded(this.offices);

  final List<OfficeSummary> offices;
}

class OfficesDirectoryError extends OfficesDirectoryState {
  const OfficesDirectoryError(this.message);

  final String message;
}
