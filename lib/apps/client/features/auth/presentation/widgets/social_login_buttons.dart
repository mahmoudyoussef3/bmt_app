import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SocialButton(
          title: 'المتابعة باستخدام Google',
          icon: 'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
          onPressed: () {
            HapticFeedback.lightImpact();
            // Mock google login
          },
        ),
        const SizedBox(height: 16),
        _SocialButton(
          title: 'المتابعة باستخدام Apple',
          icon: 'https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg',
          isApple: true,
          onPressed: () {
            HapticFeedback.lightImpact();
            // Mock apple login
          },
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String title;
  final String icon;
  final VoidCallback onPressed;
  final bool isApple;

  const _SocialButton({
    required this.title,
    required this.icon,
    required this.onPressed,
    this.isApple = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            icon,
            height: 24,
            width: 24,
            color: isApple && isDark ? Colors.white : null,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
