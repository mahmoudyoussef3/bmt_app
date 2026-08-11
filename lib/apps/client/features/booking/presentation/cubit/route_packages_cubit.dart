import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/packages/domain/usecases/get_office_packages_usecase.dart';

import 'route_packages_state.dart';

/// The commute plans sold by whoever operates the route currently open in
/// Route Details.
///
/// Its own cubit rather than a field on [RouteResultsCubit] because the two
/// answer different questions and fail differently: route results decide
/// whether the screen has anything at all, while a packages fetch that fails
/// may only ever hide one optional section.
class RoutePackagesCubit extends Cubit<RoutePackagesState> {
  RoutePackagesCubit(this._getOfficePackages)
    : super(const RoutePackagesIdle());

  final GetOfficePackagesUseCase _getOfficePackages;

  /// The office whose catalogue is currently held, so re-selecting a route from
  /// the same operator does not refetch it.
  String? _officeId;

  Future<void> loadFor(String officeId) async {
    if (officeId.isEmpty) {
      _officeId = null;
      emit(const RoutePackagesIdle());
      return;
    }
    if (officeId == _officeId) return;

    _officeId = officeId;
    emit(const RoutePackagesLoading());
    try {
      final packages = await _getOfficePackages(officeId);
      if (isClosed || _officeId != officeId) return;
      emit(RoutePackagesLoaded(packages));
    } catch (_) {
      if (isClosed || _officeId != officeId) return;
      
      emit(const RoutePackagesUnavailable());
    }
  }
}
