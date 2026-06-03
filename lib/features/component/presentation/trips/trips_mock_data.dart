import 'package:flutter/material.dart';

enum TripStatus { upcoming, inProgress, completed, cancelled }

/// Filter tabs on My Trips (Active = in progress).
enum TripFilter { upcoming, active, completed, cancelled }

extension TripFilterLabel on TripFilter {
  String get label {
    switch (this) {
      case TripFilter.upcoming:
        return 'Upcoming';
      case TripFilter.active:
        return 'Active';
      case TripFilter.completed:
        return 'Completed';
      case TripFilter.cancelled:
        return 'Cancelled';
    }
  }

  TripStatus? get statusMatch {
    switch (this) {
      case TripFilter.upcoming:
        return TripStatus.upcoming;
      case TripFilter.active:
        return TripStatus.inProgress;
      case TripFilter.completed:
        return TripStatus.completed;
      case TripFilter.cancelled:
        return TripStatus.cancelled;
    }
  }
}

enum PaymentStatus { paid, pending, refunded, failed }

class TripData {
  const TripData({
    required this.id,
    required this.reference,
    required this.status,
    required this.pickup,
    required this.destination,
    required this.dateLabel,
    required this.timeLabel,
    required this.driverName,
    required this.driverInitials,
    required this.driverRating,
    required this.vehicleName,
    required this.vehicleType,
    required this.vehicleId,
    required this.seats,
    required this.paymentStatus,
    required this.fare,
    this.cancellationReason,
    this.completedAt,
  });

  final String id;
  final String reference;
  final TripStatus status;
  final String pickup;
  final String destination;
  final String dateLabel;
  final String timeLabel;
  final String driverName;
  final String driverInitials;
  final double driverRating;
  final String vehicleName;
  final String vehicleType;
  final String vehicleId;
  final List<String> seats;
  final PaymentStatus paymentStatus;
  final String fare;
  final String? cancellationReason;
  final String? completedAt;

  String get routeLine => '$pickup → $destination';

  String get paymentLabel {
    switch (paymentStatus) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.failed:
        return 'Failed';
    }
  }

  Color paymentColor(ColorScheme scheme) {
    switch (paymentStatus) {
      case PaymentStatus.paid:
        return scheme.secondary;
      case PaymentStatus.pending:
        return scheme.tertiary;
      case PaymentStatus.refunded:
        return scheme.onSurface.withAlpha(160);
      case PaymentStatus.failed:
        return scheme.error;
    }
  }

  String get statusLabel {
    switch (status) {
      case TripStatus.upcoming:
        return 'Upcoming';
      case TripStatus.inProgress:
        return 'In progress';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }
}

const kCancellationReasons = [
  'Schedule change',
  'Found alternative transport',
  'Driver delay concern',
  'Personal emergency',
  'Duplicate booking',
  'Other',
];

const kMockTrips = [
  TripData(
    id: 'T1',
    reference: 'BMT-8K4P2N7Q',
    status: TripStatus.upcoming,
    pickup: 'Banha Station',
    destination: 'Smart Village',
    dateLabel: 'Today, Jun 3',
    timeLabel: '8:40 AM',
    driverName: 'Ahmed Mohamed',
    driverInitials: 'AM',
    driverRating: 4.9,
    vehicleName: 'Mega Coach Elite',
    vehicleType: 'Premium Coach',
    vehicleId: 'MB-15-2847',
    seats: ['6'],
    paymentStatus: PaymentStatus.paid,
    fare: 'EGP 85.00',
  ),
  TripData(
    id: 'T2',
    reference: 'BMT-3M9R1W5K',
    status: TripStatus.upcoming,
    pickup: 'Banha Center',
    destination: 'Nasr City',
    dateLabel: 'Tomorrow, Jun 4',
    timeLabel: '9:00 AM',
    driverName: 'Karim Ali',
    driverInitials: 'KA',
    driverRating: 4.7,
    vehicleName: 'City Shuttle Pro',
    vehicleType: 'Standard Shuttle',
    vehicleId: 'MB-22-1093',
    seats: ['4', '5'],
    paymentStatus: PaymentStatus.pending,
    fare: 'EGP 156.00',
  ),
  TripData(
    id: 'T3',
    reference: 'BMT-7H2C9X4L',
    status: TripStatus.inProgress,
    pickup: 'Banha Downtown',
    destination: 'Mohandessin',
    dateLabel: 'Today, Jun 3',
    timeLabel: '7:30 AM',
    driverName: 'Hassan Ibrahim',
    driverInitials: 'HI',
    driverRating: 4.6,
    vehicleName: 'Compact Commuter',
    vehicleType: 'Mini Bus',
    vehicleId: 'MB-08-7721',
    seats: ['8'],
    paymentStatus: PaymentStatus.paid,
    fare: 'EGP 92.00',
  ),
  TripData(
    id: 'T4',
    reference: 'BMT-5P1N8D2R',
    status: TripStatus.completed,
    pickup: 'Banha Station',
    destination: 'Smart Village',
    dateLabel: 'Mon, Jun 2',
    timeLabel: '8:40 AM',
    driverName: 'Ahmed Mohamed',
    driverInitials: 'AM',
    driverRating: 4.9,
    vehicleName: 'Mega Coach Elite',
    vehicleType: 'Premium Coach',
    vehicleId: 'MB-15-2847',
    seats: ['3'],
    paymentStatus: PaymentStatus.paid,
    fare: 'EGP 85.00',
    completedAt: 'Jun 2 · 9:25 AM',
  ),
  TripData(
    id: 'T5',
    reference: 'BMT-2W6K4J9M',
    status: TripStatus.completed,
    pickup: 'Smart Village Gate',
    destination: 'Banha Center',
    dateLabel: 'Fri, May 31',
    timeLabel: '6:15 PM',
    driverName: 'Omar Farouk',
    driverInitials: 'OF',
    driverRating: 4.95,
    vehicleName: 'Executive Van Plus',
    vehicleType: 'Executive Van',
    vehicleId: 'MB-31-4450',
    seats: ['2'],
    paymentStatus: PaymentStatus.paid,
    fare: 'EGP 110.00',
    completedAt: 'May 31 · 7:02 PM',
  ),
  TripData(
    id: 'T6',
    reference: 'BMT-9L3V1Q8H',
    status: TripStatus.cancelled,
    pickup: 'Banha Station',
    destination: '6th of October',
    dateLabel: 'Wed, May 29',
    timeLabel: '10:00 AM',
    driverName: 'Karim Ali',
    driverInitials: 'KA',
    driverRating: 4.7,
    vehicleName: 'City Shuttle Pro',
    vehicleType: 'Standard Shuttle',
    vehicleId: 'MB-22-1093',
    seats: ['7'],
    paymentStatus: PaymentStatus.refunded,
    fare: 'EGP 120.00',
    cancellationReason: 'Schedule change',
  ),
];

List<TripData> tripsForFilter(TripFilter filter) {
  final status = filter.statusMatch!;
  return kMockTrips.where((t) => t.status == status).toList();
}

TripData? tripById(String id) {
  for (final t in kMockTrips) {
    if (t.id == id) return t;
  }
  return null;
}

int countForFilter(TripFilter filter) => tripsForFilter(filter).length;
