import '../../domain/entities/office_summary.dart';

sealed class OfficesDirectoryState {
  const OfficesDirectoryState();
}

class OfficesDirectoryLoading extends OfficesDirectoryState {
  const OfficesDirectoryLoading();
}

class OfficesDirectoryLoaded extends OfficesDirectoryState {
  const OfficesDirectoryLoaded(this.offices, {this.query = ''});

  /// Every active office, best-rated first — the unfiltered directory.
  final List<OfficeSummary> offices;

  /// What the rider has typed into the directory search.
  final String query;

  /// The offices actually listed.
  ///
  /// Matches the office name *and* its service areas, because a rider looking
  /// for a way to Alexandria searches for the city, not for the name of a
  /// company they have never heard of.
  List<OfficeSummary> get visibleOffices {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return offices;
    return offices.where((office) {
      if (office.name.toLowerCase().contains(needle)) return true;
      return office.serviceAreas.any(
        (area) => area.toLowerCase().contains(needle),
      );
    }).toList();
  }

  /// True when the directory has offices but the query hides all of them —
  /// "nothing matched your search" is a different message from "no offices are
  /// operating yet", and only one of the two is the rider's to fix.
  bool get isFilteredEmpty => offices.isNotEmpty && visibleOffices.isEmpty;

  OfficesDirectoryLoaded copyWith({
    List<OfficeSummary>? offices,
    String? query,
  }) {
    return OfficesDirectoryLoaded(
      offices ?? this.offices,
      query: query ?? this.query,
    );
  }
}

class OfficesDirectoryError extends OfficesDirectoryState {
  const OfficesDirectoryError(this.message);

  final String message;
}
