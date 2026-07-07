import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/route_result_sort.dart';

/// The passenger's current narrowing/ordering choice on the routes
/// discovery/results grid. Operates on [PopularRouteListData] fields only —
/// see specs/002-bmt-routes-booking-ux/research.md §2 for why seats, vehicle
/// type, and time-of-day windows are filtered on Route Details instead.
@immutable
class RouteFilterCriteria {
  const RouteFilterCriteria({
    this.priceRange,
    this.durationRange,
    this.pickup,
    this.destination,
    this.sort = RouteResultSort.recommended,
  });

  final RangeValues? priceRange;
  final RangeValues? durationRange;
  final String? pickup;
  final String? destination;
  final RouteResultSort sort;

  int get activeCount => [
    priceRange,
    durationRange,
    pickup,
    destination,
  ].where((value) => value != null).length;

  RouteFilterCriteria copyWith({
    RangeValues? priceRange,
    bool clearPriceRange = false,
    RangeValues? durationRange,
    bool clearDurationRange = false,
    String? pickup,
    bool clearPickup = false,
    String? destination,
    bool clearDestination = false,
    RouteResultSort? sort,
  }) {
    return RouteFilterCriteria(
      priceRange: clearPriceRange ? null : (priceRange ?? this.priceRange),
      durationRange: clearDurationRange
          ? null
          : (durationRange ?? this.durationRange),
      pickup: clearPickup ? null : (pickup ?? this.pickup),
      destination: clearDestination ? null : (destination ?? this.destination),
      sort: sort ?? this.sort,
    );
  }

  /// Resets every filter and sort choice back to defaults (spec FR-004).
  RouteFilterCriteria reset() => const RouteFilterCriteria();

  bool matches(PopularRouteListData route) {
    if (pickup != null && route.pickup != pickup) return false;
    if (destination != null && route.destination != destination) {
      return false;
    }
    final price = priceRange;
    if (price != null) {
      final value = parsePrice(route.startingPrice);
      if (value != null && (value < price.start || value > price.end)) {
        return false;
      }
    }
    final duration = durationRange;
    if (duration != null) {
      final minutes = parseDurationMinutes(route.averageDuration);
      if (minutes != null &&
          (minutes < duration.start || minutes > duration.end)) {
        return false;
      }
    }
    return true;
  }

  int compare(PopularRouteListData a, PopularRouteListData b) {
    return switch (sort) {
      RouteResultSort.recommended ||
      RouteResultSort.tripsHigh => b.dailyTrips.compareTo(a.dailyTrips),
      RouteResultSort.priceLow =>
        (parsePrice(a.startingPrice) ?? 1 << 30).compareTo(
          parsePrice(b.startingPrice) ?? 1 << 30,
        ),
      RouteResultSort.durationShort =>
        (parseDurationMinutes(a.averageDuration) ?? 1 << 30).compareTo(
          parseDurationMinutes(b.averageDuration) ?? 1 << 30,
        ),
    };
  }

  static int? parsePrice(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? null : int.tryParse(digits);
  }

  static int? parseDurationMinutes(String value) {
    final lower = value.toLowerCase();
    final number = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(lower)?.group(1);
    if (number == null) return null;
    final parsed = double.tryParse(number);
    if (parsed == null) return null;
    if (lower.contains('hour') || lower.contains('hr') || lower.contains('h')) {
      return (parsed * 60).round();
    }
    return parsed.round();
  }
}
