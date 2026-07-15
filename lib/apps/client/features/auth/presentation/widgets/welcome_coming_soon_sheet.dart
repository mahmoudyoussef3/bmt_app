import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../routes/auth_routes.dart';

/// Presented when a mocked provider (Google / Apple / Phone) is tapped on the
/// welcome screen. Sets an honest expectation while steering the user toward
/// the working email path.
Future<void> showWelcomeComingSoonSheet(
  BuildContext context, {
  required String provider,
}) {
  return showClientBottomSheet(
    context: context,
    builder: (sheetContext) => _ComingSoonBody(provider: provider),
  );
}

class _ComingSoonBody extends StatelessWidget {
  const _ComingSoonBody({required this.provider});

  final String provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ClientBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: ClientColors.primary.withAlpha(22),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rocket_launch_rounded,
                color: ClientColors.primaryFor(context),
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: ClientSpacing.lg),
          Text(
            l10n.welcome_comingSoonTitle(provider),
            textAlign: TextAlign.center,
            style: ClientTypography.headingMedium(
              context,
            ).copyWith(color: ClientColors.textPrimaryFor(context)),
          ),
          const SizedBox(height: ClientSpacing.xs),
          Text(
            l10n.welcome_comingSoonBody,
            textAlign: TextAlign.center,
            style: ClientTypography.bodyMedium(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
            ),
          ),
          const SizedBox(height: ClientSpacing.lg),
          ClientButton(
            label: l10n.welcome_continueWithEmail,
            onPressed: () {
              final navigator = Navigator.of(context);
              navigator.pop();
              navigator.pushNamed(AuthRoutes.signIn);
            },
            icon: const Icon(
              Icons.email_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: ClientSpacing.xs),
          ClientButton.text(
            label: l10n.welcome_maybeLater,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
