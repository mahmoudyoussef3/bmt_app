import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool outline;
  final double? height;
  final Widget? icon;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outline = false,
    this.height,
    this.icon,
    this.isLoading = false,
  });

  const AppButton.primary({
    super.key,
    required String text,
    required this.onPressed,
    this.height,
    this.icon,
    this.isLoading = false,
  })  : label = text,
        outline = false;

  const AppButton.secondary({
    super.key,
    required String text,
    required this.onPressed,
    this.height,
    this.icon,
    this.isLoading = false,
  })  : label = text,
        outline = true;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    final child = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    if (outline) {
      return SizedBox(
        height: height ?? 48,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            shape: shape,
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          shape: shape,
        ),
        child: child,
      ),
    );
  }
}