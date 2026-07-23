import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_progress_bar.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Names the route being booked and how far along it the rider is, so the two
/// questions they ask mid-wizard — "am I still booking the right trip" and
/// "how much is left" — are answered without leaving the step.
class WizardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WizardAppBar({super.key, required this.step, required this.onBack});

  final int step;

  /// Null while a confirm is in flight — the booking must not be abandoned
  /// half-written.
  final VoidCallback? onBack;

  static const _progressHeight = 70.0;

  @override
  Size get preferredSize =>
      const Size.fromHeight(ClientAppBar.toolbarHeight + _progressHeight);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingWizardCubit, BookingWizardSession>(
      buildWhen: (previous, current) =>
          previous.route.routeName != current.route.routeName,
      builder: (context, session) => ClientAppBar(
        title: context.l10n.booking_bookYourSeat,
        subtitle: session.route.routeName,
        onBack: onBack,
        backEnabled: onBack != null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(_progressHeight),
          child: WizardProgressBar(step: step),
        ),
      ),
    );
  }
}
