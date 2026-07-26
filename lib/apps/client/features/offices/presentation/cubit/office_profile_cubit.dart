import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/get_office_packages_usecase.dart';

import '../../domain/usecases/get_office_routes_usecase.dart';
import '../../domain/usecases/get_office_trips_usecase.dart';
import 'office_profile_state.dart';

class OfficeProfileCubit extends Cubit<OfficeProfileState> {
  OfficeProfileCubit(
    this._getOfficeRoutes,
    this._getOfficeTrips,
    this._getOfficePackages,
  ) : super(const OfficeProfileLoading());

  final GetOfficeRoutesUseCase _getOfficeRoutes;
  final GetOfficeTripsUseCase _getOfficeTrips;
  final GetOfficePackagesUseCase _getOfficePackages;

  /// Routes, departures and packages are fetched together: the profile shows
  /// all three at once, and sequential round-trips would hold the whole screen
  /// in its skeleton for longer.
  ///
  /// Routes and departures are the critical path — a failure there is the
  /// screen's error. Packages are supplementary marketplace context, so a
  /// package fetch that fails degrades to an empty section rather than blanking
  /// the office the rider came to see.
  Future<void> load(String officeId) async {
    emit(const OfficeProfileLoading());
    try {
      final routes = _getOfficeRoutes(officeId);
      final trips = _getOfficeTrips(officeId);
      final packages = _loadPackages(officeId);
      final loaded = OfficeProfileLoaded(
        routes: await routes,
        trips: await trips,
        packages: await packages,
      );
      if (isClosed) return;
      emit(loaded);
    } catch (e) {
      if (isClosed) return;
      emit(OfficeProfileError(e.toString()));
    }
  }

  Future<List<PackagePlan>> _loadPackages(String officeId) async {
    try {
      return await _getOfficePackages(officeId);
    } catch (_) {
      return const [];
    }
  }
}
