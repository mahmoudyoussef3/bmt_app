import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_step_components.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/summary/summary_edit_strip.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/summary/summary_fare_card.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/summary/summary_ticket_card.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/summary/summary_total_row.dart';

/// The last stop before payment. It answers three questions in order: is this
/// the right ride, can I still change it, and what will I pay.
class WizardSummaryStep extends StatelessWidget {
  const WizardSummaryStep({
    super.key,
    required this.onNext,
    required this.onEditStep,
  });

  final VoidCallback onNext;
  final ValueChanged<int> onEditStep;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingWizardCubit, BookingWizardSession>(
      builder: (context, session) => Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              physics: const BouncingScrollPhysics(),
              children: [
                const BookingStepIntro(
                  icon: Icons.fact_check_rounded,
                  title: 'Review your booking',
                  subtitle: 'Nothing is charged until you pay on the next step.',
                ),
                const SizedBox(height: 18),
                SummaryTicketCard(session: session),
                const SizedBox(height: 18),
                SummaryEditStrip(onEditStep: onEditStep),
                const SizedBox(height: 18),
                SummaryFareCard(session: session),
                const SizedBox(height: 14),
                const _AssuranceNote(),
              ],
            ),
          ),
          BookingBottomAction(
            summary: SummaryTotalRow(session: session),
            child: ClientButton(
              label: 'Proceed to payment',
              icon: const Icon(Icons.arrow_forward_rounded),
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

/// Riders hesitate at checkout when they cannot tell whether the seat is
/// actually theirs yet. It is: the seat is held while they pay.
class _AssuranceNote extends StatelessWidget {
  const _AssuranceNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.verified_user_rounded,
          size: 15,
          color: ClientColors.textTertiaryFor(context),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Your seat is held while you complete payment.',
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
        ),
      ],
    );
  }
}
