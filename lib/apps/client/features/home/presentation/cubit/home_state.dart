import '../../domain/entities/home_data.dart';

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
  const HomeError(this.message);

  final String message;
}
