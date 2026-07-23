import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The [InputDecoration] shared by every auth input.
///
/// Flat and filled, like the search and support fields elsewhere in the client
/// app — the old auth field floated on its own drop shadow inside an already
/// elevated card, which is what made these screens look bolted on. Focus is
/// carried by the border and the label colour alone.
InputDecoration authFieldDecoration({
  required BuildContext context,
  required String label,
  required IconData icon,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClientRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: label,
    labelStyle: ClientTypography.bodyMedium(
      context,
    ).copyWith(color: ClientColors.textTertiaryFor(context)),
    floatingLabelStyle: ClientTypography.labelMedium(
      context,
    ).copyWith(color: ClientColors.primaryFor(context)),
    prefixIcon: Icon(
      icon,
      size: 20,
      color: ClientColors.textTertiaryFor(context),
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: ClientColors.surfaceSubtleFor(context),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: ClientSpacing.md,
      vertical: ClientSpacing.md,
    ),
    border: border(Colors.transparent),
    enabledBorder: border(ClientColors.borderFor(context)),
    focusedBorder: border(ClientColors.primaryFor(context), width: 1.5),
    errorBorder: border(ClientColors.journeyRed),
    focusedErrorBorder: border(ClientColors.journeyRed, width: 1.5),
    errorStyle: ClientTypography.bodySmall(
      context,
    ).copyWith(color: ClientColors.journeyRed),
  );
}
