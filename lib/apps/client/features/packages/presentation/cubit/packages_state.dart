import '../../domain/entities/package_filter.dart';
import '../../domain/entities/package_office.dart';
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
    this.officeFilter,
    this.selectedPackage,
    this.step = SubscriptionStep.listing,
  });

  /// The full catalogue, kept so re-filtering never needs another round trip.
  final List<PackagePlan> packages;

  /// [packages] narrowed by [filter] and [officeFilter] — what the listing
  /// renders.
  final List<PackagePlan> visiblePackages;

  final PackageFilter filter;

  /// The office the catalogue is narrowed to, by id; `null` is the whole
  /// marketplace (the default). Kept as an id, not an object, so it survives a
  /// catalogue refresh.
  final String? officeFilter;

  final PackagePlan? selectedPackage;
  final SubscriptionStep step;

  /// The distinct sellers in the catalogue — the options the office filter
  /// offers. Only offices that actually have packages appear.
  List<PackageOffice> get offices => PackageOffice.from(packages);

  /// The office currently filtered to, or `null` for the whole marketplace.
  PackageOffice? get selectedOffice {
    final id = officeFilter;
    if (id == null) return null;
    for (final office in offices) {
      if (office.id == id) return office;
    }
    return null;
  }

  /// Whether the marketplace is worth offering an office filter for at all —
  /// one office selling everything needs no "which office" control.
  bool get hasMultipleOffices => offices.length > 1;

  PackagesLoaded copyWith({
    List<PackagePlan>? visiblePackages,
    PackageFilter? filter,
    String? officeFilter,
    PackagePlan? selectedPackage,
    SubscriptionStep? step,
  }) {
    return PackagesLoaded(
      packages: packages,
      visiblePackages: visiblePackages ?? this.visiblePackages,
      filter: filter ?? this.filter,
      officeFilter: officeFilter ?? this.officeFilter,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      step: step ?? this.step,
    );
  }
}

class PackagesError extends PackagesState {
  const PackagesError(this.message);

  final String message;
}
