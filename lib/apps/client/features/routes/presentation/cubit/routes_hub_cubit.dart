import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_routes_hub_data_usecase.dart';
import 'routes_hub_state.dart';

class RoutesHubCubit extends Cubit<RoutesHubState> {
  RoutesHubCubit(this._getRoutesHubData) : super(const RoutesHubLoading());

  final GetRoutesHubDataUseCase _getRoutesHubData;

  Future<void> load() async {
    emit(const RoutesHubLoading());
    try {
      final data = await _getRoutesHubData();
      emit(RoutesHubLoaded(data));
    } catch (error) {
      emit(RoutesHubError(error.toString()));
    }
  }
}
