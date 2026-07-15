import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import 'google_g_logo.dart';

/// The third-party sign-in providers offered on the welcome screen.
///
/// These are presentation-only (mock) in this build — email/password is the
/// only real authentication path. Selecting one surfaces a "coming soon"
/// affordance handled by the caller.
enum SocialProvider { google, apple, phone }

/// A compact row of three provider buttons under an "or continue with" label.
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key, required this.onSelected});

  final ValueChanged<SocialProvider> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ProviderButton(
            label: 'Google',
            glyph: const GoogleGLogo(size: 22),
            onTap: () => _select(SocialProvider.google),
          ),
        ),
        const SizedBox(width: ClientSpacing.sm),
        Expanded(
          child: _ProviderButton(
            label: 'Apple',
            glyph: Icon(
              Icons.apple,
              size: 24,
              color: ClientColors.textPrimaryFor(context),
            ),
            onTap: () => _select(SocialProvider.apple),
          ),
        ),
        const SizedBox(width: ClientSpacing.sm),
        Expanded(
          child: _ProviderButton(
            label: context.l10n.welcome_providerPhone,
            glyph: Icon(
              Icons.phone_iphone_rounded,
              size: 22,
              color: ClientColors.primaryFor(context),
            ),
            onTap: () => _select(SocialProvider.phone),
          ),
        ),
      ],
    );
  }

  void _select(SocialProvider provider) {
    HapticFeedback.lightImpact();
    onSelected(provider);
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.glyph,
    required this.onTap,
  });

  final String label;
  final Widget glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.md),
          border: Border.all(color: ClientColors.borderFor(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            glyph,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelMedium(context).copyWith(
                  color: ClientColors.textPrimaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
