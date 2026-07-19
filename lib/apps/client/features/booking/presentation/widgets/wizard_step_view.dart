import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_confirm_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_step_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_package_step.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_payment_step.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_seat_step.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_stop_step.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_summary_step.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_trip_step.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_cubit.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_cubit.dart';

/// The wizard's body: one step at a time, sliding in the direction the rider is
/// travelling through the flow.
class WizardStepView extends StatelessWidget {
  const WizardStepView({
    super.key,
    required this.step,
    required this.confirming,
  });

  final int step;

  /// Blocks a second confirm while the first is still being written.
  final bool confirming;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(step), child: _stepFor(context)),
    );
  }

  Widget _stepFor(BuildContext context) {
    final steps = context.read<BookingWizardStepCubit>();

    return switch (step) {
      0 => WizardStopStep(onNext: steps.next),
      1 => WizardTripStep(onNext: steps.next),
      2 => BlocProvider(
        create: (_) => clientGetIt<SeatSelectionCubit>(),
        child: WizardSeatStep(onNext: steps.next),
      ),
      3 => BlocProvider(
        create: (_) => clientGetIt<PackagesCubit>(),
        child: WizardPackageStep(onNext: steps.next),
      ),
      4 => WizardSummaryStep(onNext: steps.next, onEditStep: steps.editStep),
      _ => WizardPaymentStep(
        onConfirm: confirming ? null : () => _confirm(context),
        onFix: () => steps.editStep(0),
      ),
    };
  }

  void _confirm(BuildContext context) {
    context.read<BookingWizardConfirmCubit>().confirm(
      context.read<BookingWizardCubit>().state,
    );
  }
}
