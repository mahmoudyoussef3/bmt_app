import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// A centered "prompt + action" text link used to move between the sign-in and
/// sign-up screens.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.text,
    required this.actionText,
    required this.onTap,
  });

  final String text;
  final String actionText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          text,
          style: ClientTypography.bodyMedium(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        ClientButton.text(label: actionText, onPressed: onTap),
      ],
    );
  }
}
