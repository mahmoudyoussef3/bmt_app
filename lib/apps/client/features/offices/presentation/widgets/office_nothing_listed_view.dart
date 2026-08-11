import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Shown on an office profile that publishes neither departures nor routes.
///
/// Previously this state rendered as two plain sentences — "No departures", "No
/// routes" — with nothing to tap. A rider who followed a marketplace card into
/// an office that has not published anything reached the end of the app: the
/// only way out was the back button.
///
/// An empty office is a normal, temporary condition on a marketplace, so it ends
/// with the two things a rider can still do: look at a different seller, or
/// search every route the platform sells.
class OfficeNothingListedView extends StatelessWidget {
  const OfficeNothingListedView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClientSpacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 40,
            color: ClientColors.textTertiaryFor(context),
          ),
          const SizedBox(height: ClientSpacing.md),
          Text(
            l10n.offices_nothingListedTitle,
            textAlign: TextAlign.center,
            style: ClientTypography.headingSmall(context),
          ),
          const SizedBox(height: ClientSpacing.xs),
          Text(
            l10n.offices_nothingListedBody,
            textAlign: TextAlign.center,
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: ClientSpacing.lg),
          ClientButton(
            label: l10n.offices_searchAllRoutes,
            onPressed: () =>
                Navigator.pushNamed(context, BookingRoutes.popularRoutes),
          ),
          const SizedBox(height: ClientSpacing.sm),
          ClientButton.secondary(
            label: l10n.offices_browseOtherOffices,
            
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
