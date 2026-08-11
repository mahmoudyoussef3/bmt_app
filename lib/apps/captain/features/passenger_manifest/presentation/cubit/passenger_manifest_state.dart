import '../../domain/entities/passenger.dart';

sealed class PassengerManifestState {
  const PassengerManifestState();
}

class PassengerManifestLoading extends PassengerManifestState {
  const PassengerManifestLoading();
}

class PassengerCounts {
  const PassengerCounts({
    required this.boarded,
    required this.pending,
    required this.absent,
    required this.cancelled,
    required this.total,
  });

  final int boarded;
  final int pending;
  final int absent;
  final int cancelled;
  final int total;

  int get expected => total - cancelled;

  double get boardedRatio => expected == 0 ? 0 : boarded / expected;
}

class PassengerManifestLoaded extends PassengerManifestState {
  const PassengerManifestLoaded({
    required this.visiblePassengers,
    required this.counts,
    required this.search,
    required this.statusFilter,
  });

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

class PassengerManifestUpdateError extends PassengerManifestState {
  const PassengerManifestUpdateError({
    required this.loaded,
    required this.message,
  });

  final PassengerManifestLoaded loaded;
  final String message;
}
