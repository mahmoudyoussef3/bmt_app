import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';

export 'package:bmt_app/apps/client/features/home/data/models/home_active_package_model.dart';
export 'package:bmt_app/apps/client/features/home/data/models/home_booking_model.dart';
export 'package:bmt_app/apps/client/features/home/data/models/upcoming_trip_model.dart';

/// Assembles the Home payload from rows already mapped by the row mappers.
/// Home is read-only and never round-trips through JSON, so these models map
/// Supabase rows straight to entities rather than carrying serialization.
class HomeDataModel {
  const HomeDataModel({
    required this.upcomingTrips,
    required this.bookings,
    required this.pickupSuggestions,
    required this.destinationSuggestions,
    required this.timeSuggestions,
    this.userName,
    this.activePackage,
  });

  final List<UpcomingTripData> upcomingTrips;
  final List<HomeBookingData> bookings;
  final List<String> pickupSuggestions;
  final List<String> destinationSuggestions;
  final List<String> timeSuggestions;
  final String? userName;
  final HomeActivePackageData? activePackage;

  HomeData toEntity() {
    return HomeData(
      upcomingTrips: upcomingTrips,
      bookings: bookings,
      pickupSuggestions: pickupSuggestions,
      destinationSuggestions: destinationSuggestions,
      timeSuggestions: timeSuggestions,
      userName: userName,
      activePackage: activePackage,
    );
  }
}
