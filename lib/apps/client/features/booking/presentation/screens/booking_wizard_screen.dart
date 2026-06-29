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
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/confirm_seat_booking_usecase.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/usecases/lock_trip_seat_usecase.dart';
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

  static const _titles = ['Choose Stops', 'Choose Trip', 'Select Seat', 'Choose Package', 'Review Order', 'Payment'];

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

  Future<void> _confirmBooking() async {
    final session = context.read<BookingWizardCubit>().state;
    final tripId = session.selectedTrip?.id ?? '';
    final seatId = session.selectedSeatId ?? '';

    if (tripId.isEmpty || seatId.isEmpty) return;

    setState(() => _confirming = true);

    try {
      // 1. Lock the seat for 5 minutes.
      await clientGetIt<LockTripSeatUseCase>()(tripId: tripId, seatId: seatId);

      // 2. Confirm the booking and persist to Supabase.
      final booking = await clientGetIt<ConfirmSeatBookingUseCase>()({
        'p_trip_id': tripId,
        'p_seat_id': seatId,
        'p_seat_label': session.selectedSeatLabel ?? '',
        'p_pricing_id': null,
        'p_pickup_point_id': null,
        'p_dropoff_point_id': null,
        'p_passenger_name': Supabase.instance.client.auth.currentUser
                ?.userMetadata?['full_name']
                ?.toString() ??
            '',
        'p_phone': Supabase.instance.client.auth.currentUser
                ?.userMetadata?['phone']
                ?.toString() ??
            '',
        'p_route': '${session.pickupStop?.name ?? ''} → ${session.dropoffStop?.name ?? ''}',
        'p_trip_time': session.selectedTrip?.departureTime ?? '',
        'p_trip_date': '',
        'p_payment_method': session.paymentMethod ?? 'cash_on_boarding',
        'p_payment_amount': session.totalPrice.round(),
        'p_pickup_point_name': session.pickupStop?.name ?? '',
        'p_dropoff_point_name': session.dropoffStop?.name ?? '',
        'p_receipt_url': null,
      });

      if (!mounted) return;

      final bookingId = booking['booking_id']?.toString();
      final bookingRef = booking['booking_number']?.toString() ??
          (bookingId != null && bookingId.length >= 8
              ? bookingId.substring(0, 8).toUpperCase()
              : null);

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          seat: session.selectedSeatLabel ?? '',
          vehicleId: session.selectedTrip?.vehicleType ?? '',
          driver: '',
          departureTime: session.selectedTrip?.departureTime ?? '',
          destination: session.dropoffStop?.name ?? '',
          bookingReference: bookingRef,
          bookingId: bookingId,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      final reason = e.toString().replaceFirst(RegExp(r'^Exception: ?'), '');
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: ClientColors.surfaceFor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Booking Failed',
              style: ClientTypography.headingSmall(context)
                  .copyWith(color: ClientColors.journeyRed)),
          content: Text(
            reason.contains('seat_unavailable')
                ? 'This seat was just taken. Please go back and choose another seat.'
                : reason.contains('lock_expired')
                    ? 'Your seat hold expired. Please select your seat again.'
                    : reason,
            style: ClientTypography.bodySmall(context),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: ClientColors.primary)),
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
    4 => WizardSummaryStep(onNext: _next),
    _ => WizardPaymentStep(onConfirm: _confirming ? null : _confirmBooking),
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) _back(); },
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
                    Text(_titles[_step], style: ClientTypography.bodyMedium(context)
                        .copyWith(fontWeight: FontWeight.w700)),
                    Text(session.route.routeName,
                        style: ClientTypography.labelSmall(context).copyWith(
                          color: ClientColors.textSecondaryFor(context),
                        )),
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
                  position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                      .animate(animation),
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
