import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_trip_packages_usecase.dart';
import 'packages_state.dart';

/// The fare options on offer for the trip the rider is booking — the only
/// screen that shows packages now that the standalone catalogue is gone.
///
/// It loads the *trip's* menu, not the marketplace's: the office decides per
/// trip which packages that departure sells (and may write one that exists
/// nowhere else), so a catalogue-wide read would offer packages this trip has
/// no price for.
class PackagesCubit extends Cubit<PackagesState> {
  PackagesCubit({required GetTripPackagesUseCase getTripPackages})
    : _getTripPackages = getTripPackages,
      super(const PackagesLoading());

  final GetTripPackagesUseCase _getTripPackages;

  Future<void> loadForTrip({
    required String officeId,
    required Set<String> packageIds,
  }) async {
    emit(const PackagesLoading());
    try {
      emit(
        PackagesLoaded(
          packages: await _getTripPackages(
            officeId: officeId,
            packageIds: packageIds,
          ),
        ),
      );
    } catch (error) {
      emit(PackagesError(error.toString()));
    }
  }
}
