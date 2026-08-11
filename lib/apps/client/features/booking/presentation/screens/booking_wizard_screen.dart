import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_confirm_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_confirm_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_step_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_app_bar.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_confirm_listener.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_step_view.dart';

/// Walks a rider from a route to a paid seat, one question per step.
///
/// The screen owns none of the answers: [BookingWizardCubit] holds the session,
/// [BookingWizardStepCubit] which step is showing, and
/// [BookingWizardConfirmCubit] the booking attempt.
class BookingWizardScreen extends StatelessWidget {
  const BookingWizardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingWizardStepCubit, int>(
      builder: (context, step) => PopScope(
        
        canPop: step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          
          if (_isBusy(context.read<BookingWizardConfirmCubit>().state)) return;
          context.read<BookingWizardStepCubit>().back();
        },
        child: WizardConfirmListener(
          child: BlocBuilder<BookingWizardConfirmCubit, BookingWizardConfirmState>(
            builder: (context, confirmState) {
              
              final busy = _isBusy(confirmState);

              return Stack(
                children: [
                  Scaffold(
                    backgroundColor: ClientColors.surfaceSubtleFor(context),
                    appBar: WizardAppBar(
                      step: step,
                      onBack: busy ? null : () => _back(context),
                    ),
                    body: WizardStepView(step: step, confirming: busy),
                  ),
                  if (busy) const _ConfirmBlocker(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _back(BuildContext context) {
    if (!context.read<BookingWizardStepCubit>().back()) {
      Navigator.of(context).maybePop();
    }
  }

  /// The gateway webview runs over the wizard, so the block stays up until the
  /// payment resolves rather than only while the RPC runs. Still asking the
  /// backend whether the card actually cleared counts too: letting the rider
  /// edit the booking mid-verification would let them change what they are
  /// about to be told they bought.
  static bool _isBusy(BookingWizardConfirmState state) =>
      state is BookingWizardConfirming ||
      state is BookingWizardCardCheckout ||
      state is BookingWizardVerifyingPayment;
}

/// Swallows taps while a booking is being written — a second confirm would race
/// the first for the same seat.
class _ConfirmBlocker extends StatelessWidget {
  const _ConfirmBlocker();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: CircularProgressIndicator(color: ClientColors.primary),
      ),
    );
  }
}
