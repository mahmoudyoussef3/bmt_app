import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool outline;
  final double? height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outline = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    if (outline) {
      return SizedBox(
        height: height ?? 48,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(shape: shape),
          child: Text(label),
        ),
      );
    }

    return SizedBox(
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(shape: shape),
        child: Text(label),
      ),
    );
  }
}
