import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_packages_usecase.dart';
import 'packages_state.dart';

/// The plans on offer, for the booking wizard's package step — the only screen
/// that shows them now that the standalone catalogue is gone.
class PackagesCubit extends Cubit<PackagesState> {
  PackagesCubit({required GetPackagesUseCase getPackages})
    : _getPackages = getPackages,
      super(const PackagesLoading());

  final GetPackagesUseCase _getPackages;

  Future<void> load() async {
    emit(const PackagesLoading());
    try {
      emit(PackagesLoaded(packages: await _getPackages()));
    } catch (error) {
      emit(PackagesError(error.toString()));
    }
  }
}
