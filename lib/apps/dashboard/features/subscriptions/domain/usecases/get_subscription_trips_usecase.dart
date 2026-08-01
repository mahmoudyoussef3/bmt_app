import '../entities/subscription_trip.dart';
import '../repositories/subscriptions_repository.dart';

/// The office's trips, used to filter the subscriber list down to one
/// departure and to drive the trip board.
class GetSubscriptionTripsUseCase {
  final SubscriptionsRepository _repository;

  const GetSubscriptionTripsUseCase(this._repository);

  Future<List<SubscriptionTrip>> call() {
    return _repository.getTrips();
  }
}
