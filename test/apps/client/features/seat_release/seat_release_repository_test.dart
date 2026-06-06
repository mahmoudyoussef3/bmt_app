import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/seat_release/data/datasources/mock_seat_release_datasource.dart';
import 'package:bmt_app/apps/client/features/seat_release/data/repositories/seat_release_repository_impl.dart';
import 'package:bmt_app/apps/client/features/seat_release/domain/usecases/get_seat_release_data_usecase.dart';

void main() {
  group('Client seat release repository', () {
    test('returns seat release hub data through use case', () async {
      final repository = SeatReleaseRepositoryImpl(
        const MockSeatReleaseDatasource(),
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
