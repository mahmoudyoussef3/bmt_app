import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/models/route_filter_criteria.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/day_part.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/trip_sort.dart';

/// The passenger's narrowing/ordering choice on Route Details' available
/// trips list — every dimension here has real per-trip data (research.md §2).
@immutable
class TripFilterCriteria {
  const TripFilterCriteria({
    this.priceRange,
    this.seatsRange,
    this.vehicleType,
    this.timeOfDay,
    this.sort = TripSort.earliest,
  });

  final RangeValues? priceRange;
  final RangeValues? seatsRange;
  final String? vehicleType;
  final DayPart? timeOfDay;
  final TripSort sort;

  int get activeCount => [
    priceRange,
    seatsRange,
    vehicleType,
    timeOfDay,
  ].where((value) => value != null).length;

  TripFilterCriteria copyWith({
    RangeValues? priceRange,
    bool clearPriceRange = false,
    RangeValues? seatsRange,
    bool clearSeatsRange = false,
    String? vehicleType,
    bool clearVehicleType = false,
    DayPart? timeOfDay,
    bool clearTimeOfDay = false,
    TripSort? sort,
  }) {
    return TripFilterCriteria(
      priceRange: clearPriceRange ? null : (priceRange ?? this.priceRange),
      seatsRange: clearSeatsRange ? null : (seatsRange ?? this.seatsRange),
      vehicleType: clearVehicleType ? null : (vehicleType ?? this.vehicleType),
      timeOfDay: clearTimeOfDay ? null : (timeOfDay ?? this.timeOfDay),
      sort: sort ?? this.sort,
    );
  }

  TripFilterCriteria reset() => const TripFilterCriteria();

  bool matches(RouteTripOptionData trip) {
    final price = priceRange;
    if (price != null) {
      final value = RouteFilterCriteria.parsePrice(trip.price);
      if (value != null && (value < price.start || value > price.end)) {
        return false;
      }
    }
    final seats = seatsRange;
    if (seats != null &&
        (trip.availableSeats < seats.start ||
            trip.availableSeats > seats.end)) {
      return false;
    }
    if (vehicleType != null && trip.vehicleType != vehicleType) return false;
    if (timeOfDay != null) {
      final bucket = bucketFor(trip.departureTime);
      
      if (bucket != null && bucket != timeOfDay) return false;
    }
    return true;
  }

  int compare(RouteTripOptionData a, RouteTripOptionData b) {
    return switch (sort) {
      TripSort.earliest => (parseHour24(a.departureTime) ?? 24).compareTo(
        parseHour24(b.departureTime) ?? 24,
      ),
      TripSort.priceLow =>
        (RouteFilterCriteria.parsePrice(a.price) ?? 1 << 30).compareTo(
          RouteFilterCriteria.parsePrice(b.price) ?? 1 << 30,
        ),
      TripSort.seatsHigh => b.availableSeats.compareTo(a.availableSeats),
    };
  }

  /// Extracts a 24-hour hour value from a loosely-formatted time string
  /// (e.g. "08:30 AM", "20:30", "8:30"). Returns `null` if unparseable.
  static int? parseHour24(String value) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(value);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1) ?? '');
    if (hour == null) return null;
    final isPm = value.toUpperCase().contains('PM');
    final isAm = value.toUpperCase().contains('AM');
    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    return hour.clamp(0, 23);
  }

  static DayPart? bucketFor(String departureTime) {
    final hour = parseHour24(departureTime);
    if (hour == null) return null;
    if (hour < 12) return DayPart.morning;
    if (hour < 17) return DayPart.afternoon;
    return DayPart.evening;
  }
}
