import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_confirm_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_confirm_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_booking_error_dialog.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/screens/booking_confirmation_screen.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/screens/paymob_checkout_webview_screen.dart';

/// Carries out what a confirm cannot do for itself: opening the gateway,
/// leaving for the confirmation screen, and explaining a refusal.
class WizardConfirmListener extends StatelessWidget {
  const WizardConfirmListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingWizardConfirmCubit, BookingWizardConfirmState>(
      listenWhen: (_, current) => current is! BookingWizardConfirming,
      listener: (context, state) => switch (state) {
        BookingWizardCardCheckout() => _openCardCheckout(context, state),
        BookingWizardConfirmed() => _openConfirmation(context, state),
        BookingWizardConfirmFailed() => _explainFailure(context, state),
        BookingWizardConfirmIdle() ||
        BookingWizardConfirming() ||
        
        BookingWizardVerifyingPayment() => null,
      },
      child: child,
    );
  }

  Future<void> _openCardCheckout(
    BuildContext context,
    BookingWizardCardCheckout state,
  ) async {
    final confirmCubit = context.read<BookingWizardConfirmCubit>();
    _storeBookingIds(context, state.record);

    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymobCheckoutWebViewScreen(
          checkoutUrl: state.checkoutUrl,
          bookingReference: state.record.reference ?? state.record.id ?? '',
        ),
      ),
    );

    confirmCubit.cardPaymentFinished(paid == true);
  }

  void _openConfirmation(BuildContext context, BookingWizardConfirmed state) {
    final session = context.read<BookingWizardCubit>().state;
    _storeBookingIds(context, state.record);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          seat: session.selectedSeatLabel ?? '',
          vehicleId: session.selectedTrip?.vehicle.displayName.isNotEmpty == true
              ? session.selectedTrip!.vehicle.displayName
              : session.selectedTrip?.vehicleType ?? '',
          driver: session.selectedTrip?.vehicle.driverName ?? '',
          departureTime: session.selectedTrip?.departureTime ?? '',
          destination: session.dropoffStop?.name ?? '',
          bookingReference: state.record.reference,
          bookingId: state.record.id,
          requiresVerification: state.requiresVerification,
        ),
      ),
    );
  }

  void _explainFailure(BuildContext context, BookingWizardConfirmFailed state) {
    
    context.read<BookingWizardConfirmCubit>().reset();
    showWizardBookingErrorDialog(context, reason: state.reason);
  }

  /// A booking the wizard just created is remembered on the session, so a retry
  /// settles that row instead of booking a second seat.
  void _storeBookingIds(BuildContext context, WizardBookingRecord record) {
    if (!record.isStorable) return;
    context.read<BookingWizardCubit>().setBookingId(
      bookingId: record.id!,
      bookingRef: record.reference!,
    );
  }
}
