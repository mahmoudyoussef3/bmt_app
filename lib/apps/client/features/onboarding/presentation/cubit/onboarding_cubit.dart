import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/features/onboarding/domain/usecases/check_onboarding_status_usecase.dart';
import 'package:bmt_app/apps/client/features/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final CheckOnboardingStatusUseCase _checkStatusUseCase;
  final CompleteOnboardingUseCase _completeUseCase;

  OnboardingCubit(this._checkStatusUseCase, this._completeUseCase)
      : super(OnboardingInitial());

  Future<void> checkStatus() async {
    emit(OnboardingLoading());
    try {
      final hasSeen = await _checkStatusUseCase();
      emit(OnboardingLoaded(hasSeen));
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }

  Future<void> completeOnboarding() async {
    try {
      await _completeUseCase();
      emit(OnboardingLoaded(true));
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }
}
