import '../../domain/entities/trip.dart';
import '../models/trip_model.dart';

class MockTripsDatasource {
  const MockTripsDatasource();

  Future<List<TripModel>> getTrips() async {
    return _mockTrips;
  }

  Future<TripModel?> getTripById(String id) async {
    for (final trip in _mockTrips) {
      if (trip.id == id) return trip;
    }
    return null;
  }
}

const _mockTrips = [
  TripModel(
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
  TripModel(
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
  TripModel(
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
  TripModel(
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
  TripModel(
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
  TripModel(
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
