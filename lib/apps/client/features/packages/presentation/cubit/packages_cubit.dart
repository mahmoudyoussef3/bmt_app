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

  Future<void> load() async {
    emit(const PackagesLoading());
    try {
      final packages = await _getPackages();
      emit(PackagesLoaded(packages: packages, visiblePackages: packages));
    } catch (error) {
      emit(PackagesError(error.toString()));
    }
  }

  void selectFilter(PackageFilter filter) {
    final current = state;
    if (current is! PackagesLoaded) return;
    emit(
      current.copyWith(
        filter: filter,
        visiblePackages: _filterPackages(
          packages: current.packages,
          filter: filter,
        ),
      ),
    );
  }

  /// Opens the detail pane for [package].
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
