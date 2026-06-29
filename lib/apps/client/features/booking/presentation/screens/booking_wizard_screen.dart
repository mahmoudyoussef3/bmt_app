import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_package_step.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_payment_step.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_progress_bar.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_seat_step.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_stop_step.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_summary_step.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_trip_step.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/packages_cubit.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_cubit.dart';

const _stepCount = 6;

class BookingWizardScreen extends StatefulWidget {
  const BookingWizardScreen({super.key});

  @override
  State<BookingWizardScreen> createState() => _BookingWizardScreenState();
}

class _BookingWizardScreenState extends State<BookingWizardScreen> {
  int _step = 0;

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

  void _confirmBooking() {
    final session = context.read<BookingWizardCubit>().state;
    Navigator.of(context).pushReplacementNamed(
      BookingRoutes.approval,
      arguments: {
        'routeName': session.route.routeName,
        'pickup': session.pickupStop?.name ?? '',
        'dropoff': session.dropoffStop?.name ?? '',
        'departure': session.selectedTrip?.departureTime ?? '',
        'seat': session.selectedSeatLabel ?? '',
        'package': session.selectedPackage?.name ?? 'Single Ride',
        'total': session.totalPrice.toStringAsFixed(0),
      },
    );
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
    _ => WizardPaymentStep(onConfirm: _confirmBooking),
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) _back(); },
      child: Scaffold(
        backgroundColor: ClientColors.surfaceSubtleFor(context),
        appBar: AppBar(
          backgroundColor: ClientColors.surfaceFor(context),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _back,
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
    );
  }
}
