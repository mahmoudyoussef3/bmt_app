import '../../domain/entities/booking_option.dart';

sealed class PopularRoutesState {
  const PopularRoutesState();
}

class PopularRoutesLoading extends PopularRoutesState {
  const PopularRoutesLoading();
}

class PopularRoutesLoaded extends PopularRoutesState {
  const PopularRoutesLoaded(this.routes);

  final List<PopularRouteListData> routes;
}

class PopularRoutesError extends PopularRoutesState {
  const PopularRoutesError(this.message);

  final String message;
}
