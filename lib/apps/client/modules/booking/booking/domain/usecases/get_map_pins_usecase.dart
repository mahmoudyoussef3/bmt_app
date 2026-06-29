import '../entities/booking_option.dart';
import '../repositories/booking_repository.dart';

class GetMapPinsUseCase {
  const GetMapPinsUseCase(this._repository);

  final BookingRepository _repository;

  Future<({List<MapPinOption> pickup, List<MapPinOption> destination})>
  call() async {
    final pickup = await _repository.getPickupMapPins();
    final destination = await _repository.getDestinationMapPins();
    return (pickup: pickup, destination: destination);
  }
}
