import '../../domain/entities/seat_release_data.dart';

sealed class SeatReleaseState {
  const SeatReleaseState();
}

class SeatReleaseLoading extends SeatReleaseState {
  const SeatReleaseLoading();
}

class SeatReleaseLoaded extends SeatReleaseState {
  const SeatReleaseLoaded(this.data);

  final SeatReleaseData data;
}

class SeatReleaseError extends SeatReleaseState {
  const SeatReleaseError(this.message);

  final String message;
}
