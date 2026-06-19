import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/seat_release/data/datasources/supabase_seat_release_datasource.dart';
import 'package:bmt_app/apps/client/features/seat_release/data/repositories/seat_release_repository_impl.dart';
import 'package:bmt_app/apps/client/features/seat_release/domain/entities/seat_release_data.dart';
import 'package:bmt_app/apps/client/features/seat_release/domain/usecases/get_seat_release_data_usecase.dart';

void main() {
  group('Client seat release repository', () {
    test('returns seat release hub data through use case', () async {
      final repository = SeatReleaseRepositoryImpl(
        const _FakeSeatReleaseDatasource(),
      );
      final data = await GetSeatReleaseDataUseCase(repository)();

      expect(data.packageName, 'Monthly VIP Commute');
      expect(data.remainingDays, 16);
      expect(data.releasedSeatsThisMonth, 3);
      expect(data.reasons, contains('Working From Home'));
      expect(data.upcomingTrips, hasLength(4));
      expect(data.upcomingTrips.first.seatNumber, '6');
      expect(data.pastReleases, hasLength(3));
      expect(data.pastReleases.first.status, 'Rewarded');
    });
  });
}

class _FakeSeatReleaseDatasource implements SeatReleaseDatasource {
  const _FakeSeatReleaseDatasource();

  @override
  Future<SeatReleaseData> getSeatReleaseData() async {
    return const SeatReleaseData(
      packageName: 'Monthly VIP Commute',
      packageType: 'Subscription',
      packageRoute: 'Banha - Smart Village',
      startDate: '2026-06-01',
      endDate: '2026-06-30',
      packageStatus: 'Active',
      remainingDays: 16,
      releasedSeatsThisMonth: 3,
      successfullyRebookedSeats: 2,
      totalCompensationEarned: 120,
      reasons: ['Personal plans', 'Working From Home', 'Vacation'],
      upcomingTrips: [
        UpcomingTrip(
          id: 't1',
          date: 'Today',
          pickup: 'Banha',
          destination: 'Smart Village',
          departureTime: '08:00',
          vehicle: 'Bus 12',
          seatNumber: '6',
        ),
        UpcomingTrip(
          id: 't2',
          date: 'Tomorrow',
          pickup: 'Banha',
          destination: 'Smart Village',
          departureTime: '08:00',
          vehicle: 'Bus 12',
          seatNumber: '6',
        ),
        UpcomingTrip(
          id: 't3',
          date: 'Sunday',
          pickup: 'Banha',
          destination: 'Smart Village',
          departureTime: '08:00',
          vehicle: 'Bus 12',
          seatNumber: '6',
        ),
        UpcomingTrip(
          id: 't4',
          date: 'Monday',
          pickup: 'Banha',
          destination: 'Smart Village',
          departureTime: '08:00',
          vehicle: 'Bus 12',
          seatNumber: '6',
        ),
      ],
      pastReleases: [
        SeatReleaseRecord(
          releaseId: 'r1',
          releaseDate: '2026-06-10',
          tripDate: '2026-06-11',
          route: 'Banha - Smart Village',
          seatNumber: '6',
          reason: 'Working From Home',
          notes: '',
          status: 'Rewarded',
        ),
        SeatReleaseRecord(
          releaseId: 'r2',
          releaseDate: '2026-06-12',
          tripDate: '2026-06-13',
          route: 'Banha - Smart Village',
          seatNumber: '6',
          reason: 'Vacation',
          notes: '',
          status: 'Rebooked',
        ),
        SeatReleaseRecord(
          releaseId: 'r3',
          releaseDate: '2026-06-14',
          tripDate: '2026-06-15',
          route: 'Banha - Smart Village',
          seatNumber: '6',
          reason: 'Personal plans',
          notes: '',
          status: 'Pending',
        ),
      ],
    );
  }
}
