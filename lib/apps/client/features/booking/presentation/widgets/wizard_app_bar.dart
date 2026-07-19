import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_progress_bar.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

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
      const Size.fromHeight(kToolbarHeight + _progressHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ClientColors.surfaceFor(context),
      elevation: 0,
      leading: IconButton(
        icon: const DirectionalIcon(Icons.arrow_back_rounded),
        onPressed: onBack,
      ),
      title: BlocBuilder<BookingWizardCubit, BookingWizardSession>(
        buildWhen: (previous, current) =>
            previous.route.routeName != current.route.routeName,
        builder: (context, session) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.booking_bookYourSeat,
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
        preferredSize: const Size.fromHeight(_progressHeight),
        child: WizardProgressBar(step: step),
      ),
    );
  }
}
