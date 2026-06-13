import '../../domain/entities/booking_hub_data.dart';
import '../../domain/entities/daily_booking_data.dart';

abstract class DailyBookingDatasource {
  Future<BookingHubData> getBookingHubData();
  Future<DailyBookingData> getDailyBookingData();
}
