import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// The circular success emblem on the account-success screen: a check for a
/// live session, a mail icon when email confirmation is still pending.
class AuthSuccessBadge extends StatelessWidget {
  const AuthSuccessBadge({super.key, required this.created});

  final bool created;

  @override
  Widget build(BuildContext context) {
    final color = created ? ClientColors.journeyCyan : ClientColors.primary;
    return Container(
      height: 116,
      width: 116,
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(60),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Center(
        child: Container(
          height: 78,
          width: 78,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(
            created ? Icons.check_rounded : Icons.mark_email_read_outlined,
            size: 42,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
