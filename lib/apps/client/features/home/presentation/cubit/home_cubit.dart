import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_home_data_usecase.dart';
import 'home_state.dart';

import 'package:bmt_app/core/network/api_error_handler.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getHomeData) : super(const HomeLoading());

  final GetHomeDataUseCase _getHomeData;

  Future<void> load() async {
    emit(const HomeLoading());
    try {
      final data = await _getHomeData();
      emit(HomeLoaded(data));
    } catch (error) {
      final failure = ApiErrorHandler.handle(error);
      emit(HomeError(failure.message));
    }
  }
}
