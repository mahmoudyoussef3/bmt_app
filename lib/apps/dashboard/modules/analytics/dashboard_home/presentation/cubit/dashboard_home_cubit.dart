import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_dashboard_home_usecase.dart';
import 'dashboard_home_state.dart';

class DashboardHomeCubit extends Cubit<DashboardHomeState> {
  final GetDashboardHomeUseCase _getHomeData;

  DashboardHomeCubit(this._getHomeData) : super(const DashboardHomeLoading());

  Future<void> load() async {
    emit(const DashboardHomeLoading());
    try {
      final data = await _getHomeData();
      emit(DashboardHomeLoaded(data));
    } catch (error) {
      emit(DashboardHomeError(error.toString()));
    }
  }
}
