import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';

sealed class RoutePackagesState {
  const RoutePackagesState();
}

/// Nothing asked for yet — Route Details only learns whose route it is showing
/// once the results land, so the section starts out with no office to load.
class RoutePackagesIdle extends RoutePackagesState {
  const RoutePackagesIdle();
}

class RoutePackagesLoading extends RoutePackagesState {
  const RoutePackagesLoading();
}

class RoutePackagesLoaded extends RoutePackagesState {
  const RoutePackagesLoaded(this.packages);

  /// The plans the route's operator sells. Empty is a normal answer, and the
  /// section hides itself rather than showing an empty shelf.
  final List<PackagePlan> packages;
}

/// Packages are supplementary to a route the rider can already book, so a
/// failure here hides the section instead of taking over the screen. The state
/// exists so the cubit can stop showing a spinner.
class RoutePackagesUnavailable extends RoutePackagesState {
  const RoutePackagesUnavailable();
}
