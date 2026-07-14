import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// Shared field styling for the create-ticket form, so the topic dropdown and
/// the text inputs read as one control set.
InputDecoration supportInputDecoration(BuildContext context, {String? hint}) {
  final scheme = Theme.of(context).colorScheme;

  OutlineInputBorder border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hint,
    hintStyle: ClientTypography.bodyMedium(
      context,
    ).copyWith(color: scheme.onSurfaceVariant.withAlpha(140)),
    filled: true,
    fillColor: scheme.surfaceContainerHighest.withAlpha(50),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(Colors.transparent),
    enabledBorder: border(scheme.outlineVariant.withAlpha(80)),
    focusedBorder: border(scheme.primary, width: 2),
    errorBorder: border(scheme.error),
    focusedErrorBorder: border(scheme.error, width: 2),
  );
}
