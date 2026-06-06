import '../../domain/entities/seat_release_data.dart';

class MockSeatReleaseDatasource {
  const MockSeatReleaseDatasource();

  Future<SeatReleaseData> getSeatReleaseData() async {
    return const SeatReleaseData(
      packageName: 'Monthly VIP Commute',
      packageType: 'Premium Package',
      packageRoute: 'Cairo Center ↔ Banha Express',
      startDate: 'May 20, 2026',
      endDate: 'Jun 20, 2026',
      packageStatus: 'Active',
      remainingDays: 16,
      releasedSeatsThisMonth: 3,
      successfullyRebookedSeats: 2,
      totalCompensationEarned: 150,
      reasons: [
        'Personal Plans',
        'Working From Home',
        'Vacation',
        'Transportation Alternative',
        'Medical Reason',
        'Other',
      ],
      upcomingTrips: [
        UpcomingTrip(
          id: 't1',
          date: 'Tomorrow, Jun 4',
          pickup: 'Cairo Center (Tahrir SQ)',
          destination: 'Banha Station (Gate 2)',
          departureTime: '08:00 AM',
          vehicle: 'MB-15-2847 (Comfort Van)',
          seatNumber: '6',
        ),
        UpcomingTrip(
          id: 't2',
          date: 'Friday, Jun 5',
          pickup: 'Cairo Center (Tahrir SQ)',
          destination: 'Banha Station (Gate 2)',
          departureTime: '08:00 AM',
          vehicle: 'MB-15-2847 (Comfort Van)',
          seatNumber: '6',
        ),
        UpcomingTrip(
          id: 't3',
          date: 'Monday, Jun 8',
          pickup: 'Cairo Center (Tahrir SQ)',
          destination: 'Banha Station (Gate 2)',
          departureTime: '08:00 AM',
          vehicle: 'MB-15-2847 (Comfort Van)',
          seatNumber: '6',
        ),
        UpcomingTrip(
          id: 't4',
          date: 'Tuesday, Jun 9',
          pickup: 'Cairo Center (Tahrir SQ)',
          destination: 'Banha Station (Gate 2)',
          departureTime: '08:00 AM',
          vehicle: 'MB-15-2847 (Comfort Van)',
          seatNumber: '6',
        ),
      ],
      pastReleases: [
        SeatReleaseRecord(
          releaseId: 'REL-82049',
          releaseDate: 'Jun 01, 2026',
          tripDate: 'Jun 02, 2026',
          route: 'Cairo Center → Banha Station',
          seatNumber: '6',
          reason: 'Working From Home',
          notes: 'Decided to stay home on Tuesday.',
          status: 'Rewarded',
          compensationType: 'Cashback',
          compensationAmount: 'EGP 50',
          rewardDate: 'Jun 02, 2026, 09:30 AM',
        ),
        SeatReleaseRecord(
          releaseId: 'REL-19385',
          releaseDate: 'May 24, 2026',
          tripDate: 'May 25, 2026',
          route: 'Cairo Center → Banha Station',
          seatNumber: '6',
          reason: 'Personal Plans',
          notes: 'Had a dentist appointment.',
          status: 'Rewarded',
          compensationType: 'WalletCredit',
          compensationAmount: 'EGP 100',
          rewardDate: 'May 25, 2026, 08:45 AM',
        ),
        SeatReleaseRecord(
          releaseId: 'REL-28401',
          releaseDate: 'May 19, 2026',
          tripDate: 'May 20, 2026',
          route: 'Cairo Center → Banha Station',
          seatNumber: '6',
          reason: 'Vacation',
          notes: 'Short family getaway. Seat was not rebooked.',
          status: 'Closed',
        ),
      ],
    );
  }
}
