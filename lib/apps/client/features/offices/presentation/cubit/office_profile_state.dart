import '../../domain/entities/office_route.dart';
import '../../domain/entities/office_trip.dart';

sealed class OfficeProfileState {
  const OfficeProfileState();
}

class OfficeProfileLoading extends OfficeProfileState {
  const OfficeProfileLoading();
}

/// What this office sells: the departures a rider can take a seat on today, and
/// the corridors it runs for the dates those departures do not cover.
///
/// Packages are not here. A plan has no price until a corridor prices it, so
/// they belong on Route Details — where the route exists to quote them against
/// — rather than in an unpriced catalogue on the seller's profile.
class OfficeProfileLoaded extends OfficeProfileState {
  const OfficeProfileLoaded({required this.routes, required this.trips});

  final List<OfficeRoute> routes;
  final List<OfficeTrip> trips;
}

class OfficeProfileError extends OfficeProfileState {
  const OfficeProfileError(this.message);

  final String message;
}
