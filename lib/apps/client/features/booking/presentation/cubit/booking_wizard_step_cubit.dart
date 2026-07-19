import 'package:flutter_bloc/flutter_bloc.dart';

/// Which of the wizard's steps is on screen. The state is the step index —
/// every answer the rider has given lives in [BookingWizardCubit], so moving
/// between steps never costs them one.
class BookingWizardStepCubit extends Cubit<int> {
  BookingWizardStepCubit() : super(0);

  static const stepCount = 6;

  void next() {
    if (state < stepCount - 1) emit(state + 1);
  }

  /// Returns false at the first step, where there is nothing left to go back to
  /// and the route itself should pop.
  bool back() {
    if (state == 0) return false;
    emit(state - 1);
    return true;
  }

  /// Jump straight to the step that owns a choice the rider wants to revise.
  /// Every other answer in the session survives, so a wrong seat costs one tap
  /// instead of a restart.
  void editStep(int step) {
    if (step >= 0 && step < stepCount) emit(step);
  }
}
