import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/app_spacing.dart';
import 'package:bmt_app/core/widgets/label.dart';

/// Form field with label, validation, and error display for auth screens.
class AuthLabeledField extends StatelessWidget {
  const AuthLabeledField({
    super.key,
    this.label = '',
    this.showLabel = true,
    this.hint,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.errorText,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
  });

  final String label;
  final bool showLabel;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final String? errorText;
  final bool enabled;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  bool get _hasError => errorText != null && errorText!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel && label.isNotEmpty) ...[
          Label(
            text: label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onSurface.withAlpha(210),
            ),
          ),
          AppSpacing.hSm,
        ],
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix,
            errorText: _hasError ? errorText : null,
            errorBorder: _hasError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: scheme.error, width: 2),
                  )
                : null,
            focusedErrorBorder: _hasError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: scheme.error, width: 2),
                  )
                : null,
          ),
        ),
        if (_hasError) ...[
          AppSpacing.hXs,
          Text(
            errorText!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.error, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
