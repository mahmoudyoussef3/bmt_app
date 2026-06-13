import '../../domain/entities/home_data.dart';
import 'package:bmt_app/core/network/api_result.dart';

sealed class HomeState {
  const HomeState();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  const HomeLoaded(this.data);

  final HomeData data;
}

class HomeError extends HomeState {
  const HomeError(this.failure);

  final Failure failure;
}
