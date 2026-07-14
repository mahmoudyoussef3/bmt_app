import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_package_step.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_payment_step.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_progress_bar.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_seat_step.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_stop_step.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_summary_step.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_trip_step.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_cubit.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/screens/booking_confirmation_screen.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/create_card_payment_session_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/get_payment_methods_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/screens/paymob_checkout_webview_screen.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/confirm_seat_booking_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/lock_trip_seat_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/release_trip_seat_lock_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/update_existing_booking_payment_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _stepCount = 6;

class BookingWizardScreen extends StatefulWidget {
  const BookingWizardScreen({super.key});

  @override
  State<BookingWizardScreen> createState() => _BookingWizardScreenState();
}

class _BookingWizardScreenState extends State<BookingWizardScreen> {
  int _step = 0;
  bool _confirming = false;

  void _next() {
    if (_step < _stepCount - 1) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  /// Jump straight to the step that owns a choice the rider wants to revise.
  /// Every other answer in the session survives, so a wrong seat costs one tap
  /// instead of a restart.
  void _editStep(int step) {
    if (step >= 0 && step < _stepCount) setState(() => _step = step);
  }

  Future<void> _confirmBooking() async {
    final session = context.read<BookingWizardCubit>().state;
    final tripId = session.selectedTrip?.id ?? '';
    final seatId = session.selectedSeatId ?? '';

    if (tripId.isEmpty || seatId.isEmpty) return;

    setState(() => _confirming = true);

    // The lock lives in its own transaction, so a confirm that throws leaves
    // the seat reserved-but-unbooked unless we hand it back ourselves.
    var seatLocked = false;

    try {
      late final Map<String, dynamic> booking;

      if (session.bookingId != null) {
        booking = await clientGetIt<UpdateExistingBookingPaymentUseCase>()({
          'p_booking_id': session.bookingId,
          'p_payment_method': session.paymentMethod ?? 'instapay',
          'p_receipt_url': session.receiptUrl,
          'p_payment_reference': session.paymentReference,
          'p_payer_phone': session.payerPhone,
        });
      } else {
        // 1. Lock the seat for 5 minutes.
        await clientGetIt<LockTripSeatUseCase>()(tripId: tripId, seatId: seatId);
        seatLocked = true;

        // 2. Confirm the booking and persist to Supabase.
        booking = await clientGetIt<ConfirmSeatBookingUseCase>()({
          'p_trip_id': tripId,
          'p_seat_id': seatId,
          'p_seat_label': session.selectedSeatLabel ?? '',
          'p_pricing_id': null,
          'p_pickup_point_id': session.pickupStop?.id.isEmpty == true
              ? null
              : session.pickupStop?.id,
          'p_dropoff_point_id': session.dropoffStop?.id.isEmpty == true
              ? null
              : session.dropoffStop?.id,
          'p_passenger_name':
              Supabase
                  .instance
                  .client
                  .auth
                  .currentUser
                  ?.userMetadata?['full_name']
                  ?.toString() ??
              '',
          'p_phone':
              Supabase.instance.client.auth.currentUser?.userMetadata?['phone']
                  ?.toString() ??
              '',
          'p_route':
              '${session.pickupStop?.name ?? ''} → ${session.dropoffStop?.name ?? ''}',
          'p_trip_time': session.selectedTrip?.departureTime ?? '',
          'p_trip_date': session.selectedTrip?.tripDate,
          'p_payment_method': session.paymentMethod ?? 'instapay',
          'p_payment_amount': session.totalPrice.round(),
          'p_pickup_point_name': session.pickupStop?.name ?? '',
          'p_dropoff_point_name': session.dropoffStop?.name ?? '',
          'p_package_id': session.selectedPackage?.id,
          'p_plan_start_date': session.packageStartDate?.toIso8601String().split(
            'T',
          )[0],
          'p_receipt_url': session.receiptUrl,
          'p_payment_reference': session.paymentReference,
          'p_payer_phone': session.payerPhone,
        });
      }

      if (!mounted) return;

      final bookingId = booking['booking_id']?.toString();
      final bookingRef =
          booking['booking_number']?.toString() ??
          (bookingId != null && bookingId.length >= 8
              ? bookingId.substring(0, 8).toUpperCase()
              : null);

      if (session.bookingId == null && bookingId != null && bookingRef != null) {
        context.read<BookingWizardCubit>().setBookingId(
          bookingId: bookingId,
          bookingRef: bookingRef,
        );
      }

      if (session.isCardPayment) {
        if (bookingId == null || bookingId.isEmpty) {
          throw Exception('The booking reference was not created.');
        }
        final methods = await clientGetIt<GetPaymentMethodsUseCase>()();
        final cardMethod = methods
            .where((method) => method.type == PaymentMethodType.creditCard)
            .firstOrNull;
        if (cardMethod == null) {
          throw Exception('Card payment is not available right now.');
        }
        final trip = session.selectedTrip!;
        final checkout = PaymentCheckoutData(
          tripId: trip.id,
          pickupPoint: session.pickupStop?.name ?? '',
          destination: session.dropoffStop?.name ?? '',
          vehicleNumber: trip.vehicleType,
          tripDate: trip.tripDate,
          departureTime: trip.departureTime,
          arrivalTime: trip.arrivalTime,
          selectedSeatId: seatId,
          selectedSeat: session.selectedSeatLabel ?? '',
          driverName: '',
          baseFare: session.totalPrice.round(),
        );
        final cardSession =
            await clientGetIt<CreateCardPaymentSessionUseCase>()(
              checkoutData: checkout,
              paymentMethod: cardMethod,
              bookingId: bookingId,
              amount: session.totalPrice.round(),
            );
        if (!mounted) return;
        final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PaymobCheckoutWebViewScreen(
              checkoutUrl: cardSession.checkoutUrl,
              bookingReference: bookingRef ?? bookingId,
            ),
          ),
        );
        if (paid != true) {
          throw Exception(
            'Card payment was not completed. Your booking remains pending.',
          );
        }
      }

      final isManualTransfer = session.paymentMethod == 'instapay' ||
          session.paymentMethod == 'vodafone_cash' ||
          session.paymentMethod == 'bank_transfer';

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(
            seat: session.selectedSeatLabel ?? '',
            vehicleId: session.selectedTrip?.vehicleType ?? '',
            driver: '',
            departureTime: session.selectedTrip?.departureTime ?? '',
            destination: session.dropoffStop?.name ?? '',
            bookingReference: bookingRef,
            bookingId: bookingId,
            requiresVerification: isManualTransfer,
          ),
        ),
      );
    } catch (e) {
      // Runs before the mounted check: the seat must be freed even if the user
      // has already walked away from the wizard. Once the booking row exists
      // the RPC no-ops, so a failed card payment keeps its held seat.
      if (seatLocked) {
        await clientGetIt<ReleaseTripSeatLockUseCase>()(
          tripId: tripId,
          seatId: seatId,
        );
      }

      if (!mounted) return;
      final reason = e.toString().replaceFirst(RegExp(r'^Exception: ?'), '');
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: ClientColors.surfaceFor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Booking Failed',
            style: ClientTypography.headingSmall(
              context,
            ).copyWith(color: ClientColors.journeyRed),
          ),
          content: Text(
            reason.contains('seat_unavailable')
                ? 'This seat was just taken. Please go back and choose another seat.'
                : reason.contains('lock_expired')
                ? 'Your seat hold expired. Please select your seat again.'
                : reason.contains('duplicate_active_booking')
                ? 'You already have a pending booking for this trip. Please continue payment from your existing booking.'
                : reason,
            style: ClientTypography.bodySmall(context),
          ),
          actions: [
            if (reason.contains('duplicate_active_booking'))
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).popUntil((route) => route.isFirst); // Close wizard
                },
                child: const Text(
                  'Open My Bookings',
                  style: TextStyle(color: ClientColors.primary),
                ),
              )
            else
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(color: ClientColors.primary),
                ),
              ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Widget _buildStep() => switch (_step) {
    0 => WizardStopStep(onNext: _next),
    1 => WizardTripStep(onNext: _next),
    2 => BlocProvider(
      create: (_) => clientGetIt<SeatSelectionCubit>(),
      child: WizardSeatStep(onNext: _next),
    ),
    3 => BlocProvider(
      create: (_) => clientGetIt<PackagesCubit>(),
      child: WizardPackageStep(onNext: _next),
    ),
    4 => WizardSummaryStep(onNext: _next, onEditStep: _editStep),
    _ => WizardPaymentStep(onConfirm: _confirming ? null : _confirmBooking),
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: ClientColors.surfaceSubtleFor(context),
            appBar: AppBar(
              backgroundColor: ClientColors.surfaceFor(context),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _confirming ? null : _back,
              ),
              title: BlocBuilder<BookingWizardCubit, BookingWizardSession>(
                builder: (context, session) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book your seat',
                      style: ClientTypography.bodyMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      session.route.routeName,
                      style: ClientTypography.labelSmall(
                        context,
                      ).copyWith(color: ClientColors.textSecondaryFor(context)),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: WizardProgressBar(step: _step),
              ),
            ),
            body: AnimatedSwitcher(
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
              child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
            ),
          ),
          if (_confirming)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: ClientColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
