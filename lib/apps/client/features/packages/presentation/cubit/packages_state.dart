import '../../domain/entities/package_plan.dart';

sealed class PackagesState {
  const PackagesState();
}

class PackagesLoading extends PackagesState {
  const PackagesLoading();
}

class PackagesLoaded extends PackagesState {
  const PackagesLoaded({required this.packages});

  /// Every plan on offer. The only reader is the booking wizard's package step,
  /// which prices each plan against the route the rider is already booking —
  /// there is no filtering here because there is no listing to filter.
  final List<PackagePlan> packages;
}

class PackagesError extends PackagesState {
  const PackagesError(this.message);

  final String message;
}
