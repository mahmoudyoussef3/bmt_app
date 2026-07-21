import '../../domain/entities/office_route.dart';

sealed class OfficeProfileState {
  const OfficeProfileState();
}

class OfficeProfileLoading extends OfficeProfileState {
  const OfficeProfileLoading();
}

class OfficeProfileLoaded extends OfficeProfileState {
  const OfficeProfileLoaded(this.routes);

  final List<OfficeRoute> routes;
}

class OfficeProfileError extends OfficeProfileState {
  const OfficeProfileError(this.message);

  final String message;
}
