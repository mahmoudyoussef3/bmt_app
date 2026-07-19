import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The muted, letter-spaced heading that introduces each list in the hub.
class LoyaltySectionLabel extends StatelessWidget {
  const LoyaltySectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = ClientTypography.labelMedium(
      context,
    ).copyWith(color: ClientColors.textTertiaryFor(context), letterSpacing: 0.5);

    if (trailing == null) return Text(text, style: style);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(text, style: style), trailing!],
    );
  }
}
