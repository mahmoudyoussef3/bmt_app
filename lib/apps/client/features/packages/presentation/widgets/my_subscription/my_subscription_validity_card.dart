import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/my_subscription.dart';
import '../package_section_title.dart';

/// The subscription window, drawn as the span it is: the day it opened on one
/// end, the day it closes on the other, and a meter travelling between them.
///
/// The meter fills as the window is *spent* rather than draining as it is left.
/// A bar that empties over time reads as a battery someone forgot to charge;
/// filling toward the expiry date is the same motion as the calendar.
class MySubscriptionValidityCard extends StatelessWidget {
  const MySubscriptionValidityCard({super.key, required this.subscription});

  final MySubscription subscription;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totalDays = subscription.totalDays;
    final usedDays = (totalDays - subscription.remainingDays).clamp(
      0,
      totalDays,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PackageSectionTitle(
          icon: Icons.event_available_rounded,
          title: l10n.packages_validityPeriod,
        ),
        const SizedBox(height: ClientSpacing.sm),
        ClientCard(
          padding: const EdgeInsets.all(ClientSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Endpoint(
                      label: l10n.mySubscription_started,
                      value: _formatDate(context, subscription.startDate),
                      alignment: CrossAxisAlignment.start,
                    ),
                  ),
                  const SizedBox(width: ClientSpacing.sm),
                  Expanded(
                    child: _Endpoint(
                      label: l10n.mySubscription_expires,
                      value: _formatDate(context, subscription.endDate),
                      alignment: CrossAxisAlignment.end,
                    ),
                  ),
                ],
              ),
              if (totalDays > 0) ...[
                const SizedBox(height: ClientSpacing.md),
                ClientMeter(value: 1 - subscription.remainingRatio),
                const SizedBox(height: ClientSpacing.xs),
                Text(
                  l10n.mySubscription_daysUsedOfTotal(usedDays, totalDays),
                  style: ClientTypography.labelMedium(
                    context,
                  ).copyWith(color: ClientColors.textTertiaryFor(context)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '—';
    return FormatUtil.date(context, date);
  }
}

/// One end of the window: the noun small and muted above the date it names, so
/// the two dates read as a pair of stamps rather than as a form.
class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.label,
    required this.value,
    required this.alignment,
  });

  final String label;
  final String value;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final textAlign = alignment == CrossAxisAlignment.end
        ? TextAlign.end
        : TextAlign.start;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label.toUpperCase(),
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.labelSmall(context).copyWith(
            color: ClientColors.textTertiaryFor(context),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.labelLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
