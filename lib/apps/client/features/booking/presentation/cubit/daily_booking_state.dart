import '../../domain/entities/daily_booking_data.dart';

sealed class DailyBookingState {
  const DailyBookingState();
}

class DailyBookingLoading extends DailyBookingState {
  const DailyBookingLoading();
}

class DailyBookingLoaded extends DailyBookingState {
  const DailyBookingLoaded(this.data);

  final DailyBookingData data;
}

class DailyBookingError extends DailyBookingState {
  const DailyBookingError(this.message);

  final String message;
}
