import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_office_routes_usecase.dart';
import 'office_profile_state.dart';

class OfficeProfileCubit extends Cubit<OfficeProfileState> {
  OfficeProfileCubit(this._getOfficeRoutes)
    : super(const OfficeProfileLoading());

  final GetOfficeRoutesUseCase _getOfficeRoutes;

  Future<void> load(String officeId) async {
    emit(const OfficeProfileLoading());
    try {
      emit(OfficeProfileLoaded(await _getOfficeRoutes(officeId)));
    } catch (e) {
      emit(OfficeProfileError(e.toString()));
    }
  }
}
