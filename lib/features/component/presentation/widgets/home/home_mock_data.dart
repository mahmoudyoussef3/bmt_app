import 'package:flutter/material.dart';

/// Mock data for the booking home screen (UI only).
class PopularRouteData {
  const PopularRouteData({
    required this.pickup,
    required this.destination,
    required this.duration,
    required this.startingPrice,
  });

  final String pickup;
  final String destination;
  final String duration;
  final String startingPrice;
}

class NearbyTripData {
  const NearbyTripData({
    required this.pickup,
    required this.destination,
    required this.departureTime,
    required this.seatsLeft,
    required this.isLive,
  });

  final String pickup;
  final String destination;
  final String departureTime;
  final int seatsLeft;
  final bool isLive;
}

class PackagePlanData {
  const PackagePlanData({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.badge,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String price;
  final String badge;
  final IconData icon;
}

const kPopularRoutes = [
  PopularRouteData(
    pickup: 'Banha Center',
    destination: 'Smart Village',
    duration: '45 min',
    startingPrice: 'EGP 85',
  ),
  PopularRouteData(
    pickup: 'Banha Station',
    destination: 'Nasr City',
    duration: '55 min',
    startingPrice: 'EGP 95',
  ),
  PopularRouteData(
    pickup: 'Banha Downtown',
    destination: 'Mohandessin',
    duration: '1h 10m',
    startingPrice: 'EGP 120',
  ),
  PopularRouteData(
    pickup: 'Smart Village',
    destination: 'Banha Center',
    duration: '48 min',
    startingPrice: 'EGP 85',
  ),
];

const kNearbyTrips = [
  NearbyTripData(
    pickup: 'Banha Station',
    destination: 'Smart Village',
    departureTime: '8:30 AM',
    seatsLeft: 12,
    isLive: true,
  ),
  NearbyTripData(
    pickup: 'Banha Center',
    destination: 'Nasr City',
    departureTime: '9:00 AM',
    seatsLeft: 6,
    isLive: true,
  ),
  NearbyTripData(
    pickup: 'Downtown Banha',
    destination: 'Mohandessin',
    departureTime: '9:15 AM',
    seatsLeft: 3,
    isLive: false,
  ),
];

/// Simple upcoming trip shown in the home hero (UI mock).
/// Set to `null` to preview the empty-hero state.
class HomeCurrentTripData {
  const HomeCurrentTripData({
    required this.pickup,
    required this.destination,
    required this.schedule,
    required this.statusLabel,
    this.driverLine,
  });

  final String pickup;
  final String destination;
  final String schedule;
  final String statusLabel;
  final String? driverLine;

  String get routeLabel => '$pickup → $destination';
}

const HomeCurrentTripData? kHomeCurrentTrip = HomeCurrentTripData(
  pickup: 'Banha Station',
  destination: 'Smart Village',
  schedule: 'Today, Jun 3 · Departs 8:40 AM',
  statusLabel: 'Driver assigned',
  driverLine: 'Pickup ETA 8:32 AM',
);

const kPackagePlans = [
  PackagePlanData(
    title: 'Weekly Package',
    subtitle: '5 round trips · flexible seat',
    price: 'EGP 450',
    badge: 'Popular',
    icon: Icons.date_range_rounded,
  ),
  PackagePlanData(
    title: 'Bi-Weekly Package',
    subtitle: '10 round trips · priority boarding',
    price: 'EGP 820',
    badge: 'Save 8%',
    icon: Icons.calendar_view_week_rounded,
  ),
  PackagePlanData(
    title: 'Monthly Package',
    subtitle: 'Unlimited weekdays · best value',
    price: 'EGP 1,200',
    badge: 'Best value',
    icon: Icons.calendar_month_rounded,
  ),
];

const kPickupSuggestions = [
  'Banha Center',
  'Banha Station',
  'Banha Downtown',
  'Smart Village Gate',
];

const kDestinationSuggestions = [
  'Smart Village',
  'Nasr City',
  'Mohandessin',
  '6th of October',
];

const kTimeSuggestions = [
  '7:30 AM',
  '8:00 AM',
  '8:30 AM',
  '9:00 AM',
  '9:30 AM',
];
