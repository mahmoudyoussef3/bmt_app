import 'package:flutter/material.dart';

import 'package:bmt_app/features/component/presentation/booking/booking_search_query.dart';

class RouteOptionData {
  const RouteOptionData({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.duration,
    required this.availableSeats,
    required this.startingPrice,
    this.isFastest = false,
  });

  final String id;
  final String pickup;
  final String destination;
  final String duration;
  final int availableSeats;
  final String startingPrice;
  final bool isFastest;
}

class PopularRouteListData {
  const PopularRouteListData({
    required this.routeName,
    required this.dailyTrips,
    required this.averageDuration,
    required this.startingPrice,
    required this.pickup,
    required this.destination,
  });

  final String routeName;
  final int dailyTrips;
  final String averageDuration;
  final String startingPrice;
  final String pickup;
  final String destination;
}

class AvailableTripData {
  const AvailableTripData({
    required this.vehicleType,
    required this.driverName,
    required this.estimatedArrival,
    required this.routeDuration,
    required this.availableSeats,
    required this.startingPrice,
    required this.vehicleId,
  });

  final String vehicleType;
  final String driverName;
  final String estimatedArrival;
  final String routeDuration;
  final int availableSeats;
  final String startingPrice;
  final String vehicleId;
}

class MapPinOption {
  const MapPinOption({
    required this.label,
    required this.subtitle,
    required this.offset,
  });

  final String label;
  final String subtitle;
  final Offset offset;
}

const kMapPickupOptions = [
  MapPinOption(
    label: 'Banha Center',
    subtitle: 'Main square pickup zone',
    offset: Offset(0.28, 0.62),
  ),
  MapPinOption(
    label: 'Banha Station',
    subtitle: 'Rail station entrance',
    offset: Offset(0.42, 0.48),
  ),
];

const kMapDestinationOptions = [
  MapPinOption(
    label: 'Smart Village',
    subtitle: 'Gate 3 corporate campus',
    offset: Offset(0.72, 0.32),
  ),
  MapPinOption(
    label: 'Nasr City',
    subtitle: 'Abbas El Akkad stop',
    offset: Offset(0.68, 0.55),
  ),
];

List<RouteOptionData> mockRoutesFor(BookingSearchQuery query) {
  final pickup = query.pickup.isEmpty ? 'Banha Center' : query.pickup;
  final dest = query.destination.isEmpty ? 'Smart Village' : query.destination;

  return [
    RouteOptionData(
      id: 'R1',
      pickup: pickup,
      destination: dest,
      duration: '45 min',
      availableSeats: 14,
      startingPrice: 'EGP 85',
      isFastest: true,
    ),
    RouteOptionData(
      id: 'R2',
      pickup: pickup,
      destination: dest,
      duration: '52 min',
      availableSeats: 8,
      startingPrice: 'EGP 78',
    ),
    RouteOptionData(
      id: 'R3',
      pickup: '$pickup · Express',
      destination: dest,
      duration: '38 min',
      availableSeats: 4,
      startingPrice: 'EGP 110',
    ),
  ];
}

const kPopularRouteList = [
  PopularRouteListData(
    routeName: 'Banha — Smart Village Express',
    dailyTrips: 24,
    averageDuration: '45 min',
    startingPrice: 'EGP 85',
    pickup: 'Banha Center',
    destination: 'Smart Village',
  ),
  PopularRouteListData(
    routeName: 'Station — Nasr City Line',
    dailyTrips: 18,
    averageDuration: '55 min',
    startingPrice: 'EGP 95',
    pickup: 'Banha Station',
    destination: 'Nasr City',
  ),
  PopularRouteListData(
    routeName: 'Downtown — Mohandessin',
    dailyTrips: 12,
    averageDuration: '1h 10m',
    startingPrice: 'EGP 120',
    pickup: 'Banha Downtown',
    destination: 'Mohandessin',
  ),
  PopularRouteListData(
    routeName: 'Smart Village — Banha Return',
    dailyTrips: 20,
    averageDuration: '48 min',
    startingPrice: 'EGP 85',
    pickup: 'Smart Village Gate',
    destination: 'Banha Center',
  ),
  PopularRouteListData(
    routeName: 'October Corridor',
    dailyTrips: 9,
    averageDuration: '1h 25m',
    startingPrice: 'EGP 135',
    pickup: 'Banha Station',
    destination: '6th of October',
  ),
];

List<AvailableTripData> mockAvailableTrips(BookingSearchQuery query) {
  return const [
    AvailableTripData(
      vehicleId: 'MB-15-2847',
      vehicleType: 'Premium Coach',
      driverName: 'Ahmed Mohamed',
      estimatedArrival: '8:42 AM',
      routeDuration: '45 min',
      availableSeats: 6,
      startingPrice: 'EGP 85',
    ),
    AvailableTripData(
      vehicleId: 'MB-22-1093',
      vehicleType: 'Standard Shuttle',
      driverName: 'Karim Ali',
      estimatedArrival: '8:55 AM',
      routeDuration: '52 min',
      availableSeats: 12,
      startingPrice: 'EGP 78',
    ),
    AvailableTripData(
      vehicleId: 'MB-08-7721',
      vehicleType: 'Mini Bus',
      driverName: 'Hassan Ibrahim',
      estimatedArrival: '9:05 AM',
      routeDuration: '48 min',
      availableSeats: 3,
      startingPrice: 'EGP 92',
    ),
    AvailableTripData(
      vehicleId: 'MB-31-4450',
      vehicleType: 'Executive Van',
      driverName: 'Omar Farouk',
      estimatedArrival: '9:12 AM',
      routeDuration: '38 min',
      availableSeats: 2,
      startingPrice: 'EGP 110',
    ),
  ];
}
