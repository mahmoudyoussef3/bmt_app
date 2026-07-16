import '../../domain/entities/passenger.dart';

sealed class PassengerManifestState {
  const PassengerManifestState();
}

class PassengerManifestLoading extends PassengerManifestState {
  const PassengerManifestLoading();
}

/// Boarding tallies across the *whole* manifest.
///
/// Deliberately independent of the search and status filter: these drive the
/// header and the progress bar, which report the trip's real boarding
/// position. They must not move because the captain typed a name into the
/// search box.
class PassengerCounts {
  const PassengerCounts({
    required this.boarded,
    required this.pending,
    required this.absent,
    required this.late,
    required this.total,
  });

  final int boarded;
  final int pending;
  final int absent;
  final int late;
  final int total;

  double get boardedRatio => total == 0 ? 0 : boarded / total;
}

class PassengerManifestLoaded extends PassengerManifestState {
  const PassengerManifestLoaded({
    required this.visiblePassengers,
    required this.counts,
    required this.search,
    required this.statusFilter,
  });

  /// The manifest after the current search and status filter.
  final List<Passenger> visiblePassengers;

  final PassengerCounts counts;
  final String search;
  final PassengerBoardingStatus? statusFilter;

  bool get isFiltering => search.isNotEmpty || statusFilter != null;
}

class PassengerManifestError extends PassengerManifestState {
  const PassengerManifestError(this.message);

  final String message;
}

/// A failed status write. Carries the rolled-back manifest so the list stays
/// on screen while the failure is reported.
class PassengerManifestUpdateError extends PassengerManifestState {
  const PassengerManifestUpdateError({
    required this.loaded,
    required this.message,
  });

  final PassengerManifestLoaded loaded;
  final String message;
}
