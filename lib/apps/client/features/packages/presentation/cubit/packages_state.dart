import '../../domain/entities/package_filter.dart';
import '../../domain/entities/package_plan.dart';

/// Which pane of the subscription flow is showing. The rider picks a package on
/// [listing] and reviews it on [details] before continuing to payment, which is
/// a separate feature and route.
enum SubscriptionStep { listing, details }

sealed class PackagesState {
  const PackagesState();
}

class PackagesLoading extends PackagesState {
  const PackagesLoading();
}

class PackagesLoaded extends PackagesState {
  const PackagesLoaded({
    required this.packages,
    required this.visiblePackages,
    this.filter = PackageFilter.all,
    this.selectedPackage,
    this.step = SubscriptionStep.listing,
  });

  /// The full catalogue, kept so re-filtering never needs another round trip.
  final List<PackagePlan> packages;

  /// [packages] narrowed by [filter] — what the listing renders.
  final List<PackagePlan> visiblePackages;

  final PackageFilter filter;
  final PackagePlan? selectedPackage;
  final SubscriptionStep step;

  PackagesLoaded copyWith({
    List<PackagePlan>? visiblePackages,
    PackageFilter? filter,
    PackagePlan? selectedPackage,
    SubscriptionStep? step,
  }) {
    return PackagesLoaded(
      packages: packages,
      visiblePackages: visiblePackages ?? this.visiblePackages,
      filter: filter ?? this.filter,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      step: step ?? this.step,
    );
  }
}

class PackagesError extends PackagesState {
  const PackagesError(this.message);

  final String message;
}
