import '../../domain/entities/route_details.dart';

sealed class RouteDetailsState {
  const RouteDetailsState();
}

class RouteDetailsLoading extends RouteDetailsState {
  const RouteDetailsLoading();
}

class RouteDetailsLoaded extends RouteDetailsState {
  const RouteDetailsLoaded(this.details);

  final RouteDetails details;
}

class RouteDetailsError extends RouteDetailsState {
  const RouteDetailsError(this.message);

  final String message;
}
