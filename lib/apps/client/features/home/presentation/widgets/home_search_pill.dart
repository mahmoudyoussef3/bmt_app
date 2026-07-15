import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// The "Where to?" search bar — the primary entry point into the booking
/// flow, styled as a bold elevated pill sitting on the hero gradient.
class HomeSearchPill extends StatelessWidget {
  const HomeSearchPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 16, 12),
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.pill),
          boxShadow: ClientElevation.md(context),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: ClientColors.primaryFor(context).withAlpha(18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                color: ClientColors.primaryFor(context),
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.home_whereTo,
                    style: ClientTypography.headingSmall(
                      context,
                    ).copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    context.l10n.home_searchRoutesTimesSeats,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.bodySmall(
                      context,
                    ).copyWith(color: ClientColors.textSecondaryFor(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ClientColors.primaryFor(context),
                shape: BoxShape.circle,
              ),
              child: const DirectionalIcon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
