import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The "Forgot password?" link that sits opposite the remember-me control.
class ForgotPasswordLink extends StatelessWidget {
  const ForgotPasswordLink({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: ClientColors.primaryFor(context),
        padding: const EdgeInsets.symmetric(horizontal: ClientSpacing.xs),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: ClientTypography.labelMedium(context),
      ),
      child: Text(context.l10n.auth_forgotPassword),
    );
  }
}
