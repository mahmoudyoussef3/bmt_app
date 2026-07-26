import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';

import '../../domain/entities/office_route.dart';
import '../../domain/entities/office_trip.dart';

sealed class OfficeProfileState {
  const OfficeProfileState();
}

class OfficeProfileLoading extends OfficeProfileState {
  const OfficeProfileLoading();
}

/// What this office sells: the departures a rider can take a seat on today, the
/// corridors it runs for the dates those departures do not cover, and the
/// commute packages it offers — the discovery loop closing back on the office.
class OfficeProfileLoaded extends OfficeProfileState {
  const OfficeProfileLoaded({
    required this.routes,
    required this.trips,
    this.packages = const [],
  });

  final List<OfficeRoute> routes;
  final List<OfficeTrip> trips;
  final List<PackagePlan> packages;
}

class OfficeProfileError extends OfficeProfileState {
  const OfficeProfileError(this.message);

  final String message;
}
