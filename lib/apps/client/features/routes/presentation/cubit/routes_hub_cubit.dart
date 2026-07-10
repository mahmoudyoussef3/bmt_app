import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_routes_hub_data_usecase.dart';
import 'routes_hub_state.dart';

class RoutesHubCubit extends Cubit<RoutesHubState> {
  RoutesHubCubit(this._getRoutesHubData) : super(const RoutesHubLoading());

  final GetRoutesHubDataUseCase _getRoutesHubData;

  /// Loads routes hub data. When content is already on screen
  /// (pull-to-refresh), the loaded state is kept instead of flashing the
  /// skeleton; a refresh failure also keeps the existing content rather than
  /// replacing it with a full-screen error.
  Future<void> load() async {
    final previous = state;
    if (previous is! RoutesHubLoaded) emit(const RoutesHubLoading());
    try {
      final data = await _getRoutesHubData();
      emit(RoutesHubLoaded(data));
    } catch (error) {
      if (previous is RoutesHubLoaded) {
        emit(RoutesHubLoaded(previous.data, refreshFailure: error.toString()));
      } else {
        emit(RoutesHubError(error.toString()));
      }
    }
  }
}
