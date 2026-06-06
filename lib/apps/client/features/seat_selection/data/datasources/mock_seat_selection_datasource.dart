import '../../domain/entities/seat_option.dart';
import '../models/seat_selection_model.dart';

class MockSeatSelectionDatasource {
  const MockSeatSelectionDatasource();

  Future<SeatSelectionModel> getSeatSelectionData() async {
    return _mockSeatSelectionData;
  }
}

const _mockSeatSelectionData = SeatSelectionModel(
  seats: [
    SeatOptionModel(id: '1', availability: SeatAvailability.reserved),
    SeatOptionModel(id: '2', availability: SeatAvailability.reserved),
    SeatOptionModel(id: '3', availability: SeatAvailability.reserved),
    SeatOptionModel(id: '4', availability: SeatAvailability.available),
    SeatOptionModel(id: '5', availability: SeatAvailability.available),
    SeatOptionModel(id: '6', availability: SeatAvailability.available),
    SeatOptionModel(id: '7', availability: SeatAvailability.available),
    SeatOptionModel(id: '8', availability: SeatAvailability.reserved),
    SeatOptionModel(id: '9', availability: SeatAvailability.available),
    SeatOptionModel(id: '10', availability: SeatAvailability.available),
    SeatOptionModel(id: '11', availability: SeatAvailability.available),
    SeatOptionModel(id: '12', availability: SeatAvailability.available),
    SeatOptionModel(id: '13', availability: SeatAvailability.reserved),
    SeatOptionModel(id: '14', availability: SeatAvailability.available),
    SeatOptionModel(id: '15', availability: SeatAvailability.available),
  ],
  pricePerSeat: 25,
  pickupPoint: 'Banha Station',
  destination: 'Smart Village',
  vehicleNumber: 'MB-15-2847',
  vehicleName: 'Mega Coach Elite',
  vehicleType: 'Premium Coach',
  vehicleModel: 'Mercedes-Benz Tourismo 2024',
  departureTime: '8:40 AM',
  arrivalTime: '9:20 AM',
  driverName: 'Ahmed Mohamed',
  driverRating: 4.9,
);
