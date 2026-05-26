part of 'subscription_cubit.dart';

class SubscriptionState {
  final Location? pickupLocation;
  final Location? dropoffLocation;
  final DateTime? preferredArrival;
  final Seat? preferredSeat;
  final MonthlySubscription? createdSubscription;
  final bool isSubmitted;

  const SubscriptionState({
    this.pickupLocation,
    this.dropoffLocation,
    this.preferredArrival,
    this.preferredSeat,
    this.createdSubscription,
    this.isSubmitted = false,
  });

  SubscriptionState copyWith({
    Location? pickupLocation,
    Location? dropoffLocation,
    DateTime? preferredArrival,
    Seat? preferredSeat,
    MonthlySubscription? createdSubscription,
    bool? isSubmitted,
  }) {
    return SubscriptionState(
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      preferredArrival: preferredArrival ?? this.preferredArrival,
      preferredSeat: preferredSeat ?? this.preferredSeat,
      createdSubscription: createdSubscription ?? this.createdSubscription,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }
}
