import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// Terms & Privacy footer links.
class TermsFooter extends StatelessWidget {
  const TermsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final linkStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: scheme.onSurface.withAlpha(170),
      height: 1.5,
    );

    void showPolicyNotice(String title) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title will open when published.')),
      );
    }

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'Terms & Conditions',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => showPolicyNotice('Terms & Conditions'),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => showPolicyNotice('Privacy Policy'),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
