import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A small, muted, centered helper note shown at the foot of an auth form.
class AuthSecurityNote extends StatelessWidget {
  const AuthSecurityNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: ClientTypography.bodySmall(
        context,
      ).copyWith(color: ClientColors.textTertiaryFor(context)),
    );
  }
}
