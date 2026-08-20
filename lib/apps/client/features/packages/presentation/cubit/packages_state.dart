import '../../domain/entities/package_plan.dart';

sealed class PackagesState {
  const PackagesState();
}

class PackagesLoading extends PackagesState {
  const PackagesLoading();
}

class PackagesLoaded extends PackagesState {
  const PackagesLoaded({required this.packages});

  /// The trip's fare menu, in the order the office published it. The only
  /// reader is the booking wizard's package step, which prices each plan
  /// against the exact stops the rider picked — there is no filtering here
  /// because the read is already scoped to one trip.
  final List<PackagePlan> packages;
}

class PackagesError extends PackagesState {
  const PackagesError(this.message);

  final String message;
}
