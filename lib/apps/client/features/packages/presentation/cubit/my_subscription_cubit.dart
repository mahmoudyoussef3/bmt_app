import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_my_subscription_usecase.dart';
import 'my_subscription_state.dart';

class MySubscriptionCubit extends Cubit<MySubscriptionState> {
  MySubscriptionCubit(this._getMySubscription)
    : super(const MySubscriptionLoading());

  final GetMySubscriptionUseCase _getMySubscription;

  Future<void> load() async {
    emit(const MySubscriptionLoading());
    try {
      final subscription = await _getMySubscription();
      emit(
        subscription == null
            ? const MySubscriptionEmpty()
            : MySubscriptionLoaded(subscription),
      );
    } catch (error) {
      emit(MySubscriptionError(error.toString()));
    }
  }
}
