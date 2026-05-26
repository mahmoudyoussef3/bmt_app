import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/shared/models/models.dart';
import 'package:bmt_app/shared/mock_data/mock_data.dart';

part 'subscription_state.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit() : super(const SubscriptionState());

  void selectPickupLocation(Location location) {
    emit(state.copyWith(pickupLocation: location));
  }

  void selectDropoffLocation(Location location) {
    emit(state.copyWith(dropoffLocation: location));
  }

  void selectArrivalTime(DateTime time) {
    emit(state.copyWith(preferredArrival: time));
  }

  void selectPreferredSeat(Seat seat) {
    emit(state.copyWith(preferredSeat: seat));
  }

  void submitSubscription() {
    final subscription = MonthlySubscription(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      user: MockData.currentUser,
      pickupLocation: state.pickupLocation ?? MockData.locations[0],
      dropoffLocation: state.dropoffLocation ?? MockData.locations[2],
      preferredArrival: state.preferredArrival ?? DateTime.now(),
      preferredSeat: state.preferredSeat ?? MockData.vehicles[0].seats[0],
      startDate: DateTime.now(),
      isActive: true,
      monthlyPrice: 1000.0,
    );
    emit(state.copyWith(createdSubscription: subscription, isSubmitted: true));
  }

  void reset() {
    emit(const SubscriptionState());
  }
}
