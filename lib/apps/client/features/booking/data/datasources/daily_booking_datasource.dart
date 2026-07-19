import '../../domain/entities/daily_booking_data.dart';

abstract class DailyBookingDatasource {
  Future<DailyBookingData> getDailyBookingData();
}
