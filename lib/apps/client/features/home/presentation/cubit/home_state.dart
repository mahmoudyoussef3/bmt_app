import '../../domain/entities/home_data.dart';
import 'package:bmt_app/core/network/api_result.dart';

sealed class HomeState {
  const HomeState();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  const HomeLoaded(this.data, {this.refreshFailure});

  final HomeData data;

  /// Set when a pull-to-refresh failed while this data was on screen —
  /// the UI keeps the content and surfaces the failure non-destructively.
  final Failure? refreshFailure;
}

class HomeError extends HomeState {
  const HomeError(this.failure);

  final Failure failure;
}
