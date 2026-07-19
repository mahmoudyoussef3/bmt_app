import 'package:flutter/material.dart';

/// The focus-aware fill + shadow wrapper drawn behind an auth field.
BoxDecoration authFieldContainerDecoration({
  required BuildContext context,
  required bool isFocused,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  final fillColor = isFocused
      ? (isDark ? const Color(0xFF0F172A) : Colors.white)
      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC));

  return BoxDecoration(
    color: fillColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      isFocused
          ? BoxShadow(
              color: scheme.primary.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
          : BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
    ],
  );
}

/// Builds the [InputDecoration] shared by [PremiumAuthTextField]: a themed
/// label, prefix icon, optional [suffixIcon] and focus-aware rounded borders.
InputDecoration authFieldInputDecoration({
  required BuildContext context,
  required bool isFocused,
  required String labelText,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  OutlineInputBorder border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: labelText,
    labelStyle: TextStyle(
      color: isFocused
          ? scheme.primary
          : scheme.onSurfaceVariant.withValues(alpha: 0.75),
      fontWeight: isFocused ? FontWeight.w800 : FontWeight.w600,
    ),
    prefixIcon: Icon(
      prefixIcon,
      color: isFocused
          ? scheme.primary
          : scheme.onSurfaceVariant.withValues(alpha: 0.65),
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.transparent,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: border(Colors.transparent),
    enabledBorder: border(
      isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
    ),
    focusedBorder: border(scheme.primary, width: 2),
    errorBorder: border(scheme.error),
    focusedErrorBorder: border(scheme.error, width: 2),
  );
}
