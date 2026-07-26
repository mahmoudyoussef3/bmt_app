import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/package_filter.dart';
import '../../domain/entities/package_plan.dart';
import '../../domain/usecases/filter_packages_usecase.dart';
import '../../domain/usecases/get_packages_usecase.dart';
import 'packages_state.dart';

class PackagesCubit extends Cubit<PackagesState> {
  PackagesCubit({
    required GetPackagesUseCase getPackages,
    required FilterPackagesUseCase filterPackages,
  }) : _getPackages = getPackages,
       _filterPackages = filterPackages,
       super(const PackagesLoading());

  final GetPackagesUseCase _getPackages;
  final FilterPackagesUseCase _filterPackages;

  /// Loads the marketplace catalogue. [initialOfficeId] pre-selects the office
  /// lens — an office profile opens the marketplace already narrowed to itself.
  Future<void> load({String? initialOfficeId}) async {
    emit(const PackagesLoading());
    try {
      final packages = await _getPackages();
      final officeId = (initialOfficeId != null && initialOfficeId.isNotEmpty)
          ? initialOfficeId
          : null;
      emit(
        PackagesLoaded(
          packages: packages,
          officeFilter: officeId,
          visiblePackages: _applyFilters(
            packages,
            filter: PackageFilter.all,
            officeId: officeId,
          ),
        ),
      );
    } catch (error) {
      emit(PackagesError(error.toString()));
    }
  }

  /// Narrows the catalogue by trip duration, keeping any office filter in place.
  void selectFilter(PackageFilter filter) {
    final current = state;
    if (current is! PackagesLoaded) return;
    emit(
      current.copyWith(
        filter: filter,
        visiblePackages: _applyFilters(
          current.packages,
          filter: filter,
          officeId: current.officeFilter,
        ),
      ),
    );
  }

  /// Narrows the catalogue to one selling office, or clears the office lens when
  /// [officeId] is `null` ("all offices"). Duration stays as the rider left it.
  void selectOffice(String? officeId) {
    final current = state;
    if (current is! PackagesLoaded) return;
    // copyWith cannot set a nullable field back to null, so a clear rebuilds the
    // state explicitly.
    emit(
      PackagesLoaded(
        packages: current.packages,
        visiblePackages: _applyFilters(
          current.packages,
          filter: current.filter,
          officeId: officeId,
        ),
        filter: current.filter,
        officeFilter: officeId,
        selectedPackage: current.selectedPackage,
        step: current.step,
      ),
    );
  }

  List<PackagePlan> _applyFilters(
    List<PackagePlan> packages, {
    required PackageFilter filter,
    String? officeId,
  }) => _filterPackages(packages: packages, filter: filter, officeId: officeId);

  /// Opens the detail pane for [package]. Reachable from the marketplace with or
  /// without a trip in hand — details are pure discovery; only the final
  /// subscribe step needs a trip, which the detail CTA handles.
  void openDetails(PackagePlan package) {
    final current = state;
    if (current is! PackagesLoaded) return;
    emit(
      current.copyWith(
        selectedPackage: package,
        step: SubscriptionStep.details,
      ),
    );
  }

  /// Steps back to the listing. Returns false when already at the first pane,
  /// which tells the screen to pop the route instead.
  bool goBack() {
    final current = state;
    if (current is! PackagesLoaded) return false;
    if (current.step == SubscriptionStep.listing) return false;
    emit(current.copyWith(step: SubscriptionStep.listing));
    return true;
  }
}
