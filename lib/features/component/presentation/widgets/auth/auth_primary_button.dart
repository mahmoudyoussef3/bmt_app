import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/spinner.dart';

/// Primary CTA with optional loading placeholder (no real async work).
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.outline = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Spinner(size: 22),
        ),
      );
    }

    if (onPressed == null) {
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      );
      return SizedBox(
        height: 52,
        child: outline
            ? OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(shape: shape),
                child: Text(label),
              )
            : ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(shape: shape),
                child: Text(label),
              ),
      );
    }

    return AppButton(
      label: label,
      outline: outline,
      height: 52,
      onPressed: onPressed!,
    );
  }
}
