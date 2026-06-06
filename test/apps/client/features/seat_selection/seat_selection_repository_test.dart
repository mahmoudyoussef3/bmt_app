import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/seat_selection/data/datasources/mock_seat_selection_datasource.dart';
import 'package:bmt_app/apps/client/features/seat_selection/data/repositories/seat_selection_repository_impl.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/entities/seat_option.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/get_seat_selection_data_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/select_seat_usecase.dart';

void main() {
  group('Client seat selection', () {
    late SeatSelectionRepositoryImpl repository;

    setUp(() {
      repository = const SeatSelectionRepositoryImpl(
        MockSeatSelectionDatasource(),
      );
    });

    test('returns the seat map and trip summary data', () async {
      final data = await GetSeatSelectionDataUseCase(repository)();

      expect(data.seats, hasLength(15));
      expect(data.availableCount, 10);
      expect(data.pricePerSeat, 25);
      expect(data.route, 'Banha Station → Smart Village');
    });

    test('selects and toggles an available seat', () async {
      final data = await GetSeatSelectionDataUseCase(repository)();
      const selectSeat = SelectSeatUseCase();

      final selected = selectSeat(
        seats: data.seats,
        currentSeatId: null,
        seatId: '6',
      );
      final toggled = selectSeat(
        seats: data.seats,
        currentSeatId: selected,
        seatId: '6',
      );

      expect(selected, '6');
      expect(toggled, isNull);
    });

    test('does not select a reserved seat', () async {
      final data = await GetSeatSelectionDataUseCase(repository)();
      const selectSeat = SelectSeatUseCase();

      final selected = selectSeat(
        seats: data.seats,
        currentSeatId: '6',
        seatId: '1',
      );

      expect(data.seats.first.availability, SeatAvailability.reserved);
      expect(selected, '6');
    });
  });
}
