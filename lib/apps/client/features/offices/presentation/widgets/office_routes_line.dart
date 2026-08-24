import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// How every operator card ends: the size of the network behind the name.
///
/// A rider choosing between companies is really asking "how much does this
/// one run?", and the route count answers it in the card itself instead of
/// making them open four profiles to compare. It is drawn in the brand accent
/// so it also reads as the card's live edge — the thing tapping leads to.
///
/// An office whose count is unknown or zero falls back to naming what the
/// card opens, so a listing never ends on a blank line.
///
/// Shared by the directory listing and Home's rail so an operator closes the
/// same way wherever a rider meets it.
class OfficeRoutesLine extends StatelessWidget {
  const OfficeRoutesLine({super.key, required this.count, this.dense = false});

  final int count;

  /// Tighter type for the Home rail's narrower tile.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Text(
      count > 0 ? l10n.offices_routesCount(count) : l10n.offices_openProfile,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style:
          (dense
                  ? ClientTypography.labelMedium(context)
                  : ClientTypography.labelLarge(context))
              .copyWith(
                color: ClientColors.primaryFor(context),
                fontWeight: FontWeight.w800,
              ),
    );
  }
}
