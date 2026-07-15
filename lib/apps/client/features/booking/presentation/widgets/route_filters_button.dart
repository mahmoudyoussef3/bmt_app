import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The single entry point into the routes filter+sort sheet, with an
/// active-count badge (spec FR-004: active filters must be visible at a
/// glance).
class RouteFiltersButton extends StatelessWidget {
  const RouteFiltersButton({
    super.key,
    required this.activeCount,
    required this.onTap,
  });

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = activeCount > 0;

    final label = active
        ? context.l10n.booking_filtersCount(activeCount)
        : context.l10n.booking_filters;

    return Semantics(
      button: true,
      label: active
          ? context.l10n.booking_filtersActiveSemantics(label)
          : label,
      child: PressableScale(
        onTap: onTap,
        scale: 0.96,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active
                ? ClientColors.primaryFor(context)
                : ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.md),
            border: Border.all(
              color: active
                  ? Colors.transparent
                  : ClientColors.borderFor(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_alt_rounded,
                size: 20,
                color: active ? ClientColors.textInverse : null,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: ClientTypography.labelLarge(context).copyWith(
                  color: active ? ClientColors.textInverse : null,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
