import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

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
            '$provider sign-in is coming soon',
            textAlign: TextAlign.center,
            style: ClientTypography.headingMedium(
              context,
            ).copyWith(color: ClientColors.textPrimaryFor(context)),
          ),
          const SizedBox(height: ClientSpacing.xs),
          Text(
            'We\'re still putting the finishing touches on it. For now, continue '
            'with your email to book trips and track buses right away.',
            textAlign: TextAlign.center,
            style: ClientTypography.bodyMedium(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
            ),
          ),
          const SizedBox(height: ClientSpacing.lg),
          ClientButton(
            label: 'Continue with Email',
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
            label: 'Maybe later',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
