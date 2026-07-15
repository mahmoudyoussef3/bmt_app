import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

/// Terms & Privacy footer links.
class TermsFooter extends StatelessWidget {
  const TermsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
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
        SnackBar(content: Text(l10n.auth_policyComingSoon(title))),
      );
    }

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: l10n.auth_termsPrefix),
          TextSpan(
            text: l10n.auth_termsAndConditions,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => showPolicyNotice(l10n.auth_termsAndConditions),
          ),
          TextSpan(text: l10n.auth_termsAnd),
          TextSpan(
            text: l10n.auth_privacyPolicy,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => showPolicyNotice(l10n.auth_privacyPolicy),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
