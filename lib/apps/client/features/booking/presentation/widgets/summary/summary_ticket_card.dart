import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/dashed_divider.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/summary/summary_ticket_facts.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/summary/summary_ticket_journey.dart';

/// The booking the rider is about to pay for, drawn as the ticket they will
/// end up holding. Showing the outcome — not a table of the inputs they typed —
/// is what makes this screen reviewable at a glance.
class SummaryTicketCard extends StatelessWidget {
  const SummaryTicketCard({super.key, required this.session});

  final BookingWizardSession session;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        boxShadow: ClientElevation.md(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        child: ColoredBox(
          color: ClientColors.surfaceFor(context),
          child: Column(
            children: [
              _Header(session: session),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                child: SummaryTicketJourney(session: session),
              ),
              const _TearLine(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: SummaryTicketFacts(session: session),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.session});

  final BookingWizardSession session;

  @override
  Widget build(BuildContext context) {
    final day = formatTripDay(context, session.selectedTrip?.tripDate ?? '');

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: ClientColors.primaryGradientFor(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your ticket',
                  style: ClientTypography.labelSmall(
                    context,
                  ).copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 3),
                Text(
                  session.route.routeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (day.isNotEmpty) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(46),
                borderRadius: BorderRadius.circular(ClientRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    day,
                    style: ClientTypography.labelMedium(
                      context,
                    ).copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The perforation between the journey and the stub. The two half-circles are
/// punched in the wizard's page color — not [ClientColors.backgroundFor] — so
/// they stay invisible against the scaffold in dark mode too.
class _TearLine extends StatelessWidget {
  const _TearLine();

  @override
  Widget build(BuildContext context) {
    final page = ClientColors.surfaceSubtleFor(context);

    return Row(
      children: [
        _Notch(color: page, alignRight: true),
        Expanded(
          child: DashedDivider(color: ClientColors.borderStrongFor(context)),
        ),
        _Notch(color: page, alignRight: false),
      ],
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch({required this.color, required this.alignRight});

  final Color color;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(10);
    return Container(
      width: 10,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: alignRight
            ? const BorderRadius.horizontal(right: radius)
            : const BorderRadius.horizontal(left: radius),
      ),
    );
  }
}
