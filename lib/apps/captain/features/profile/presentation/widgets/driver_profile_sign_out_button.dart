import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_confirm_dialog.dart';
import 'package:bmt_app/apps/captain/features/auth/presentation/cubit/captain_auth_cubit.dart';

/// Signing out is confirmed first — a mis-tap here drops the captain's session
/// mid-shift.
///
/// Reached from both the loaded profile and the error body, and the error body
/// renders when the profile could not load at all, so this resolves the auth
/// cubit from the locator rather than the widget tree: there is no guaranteed
/// `CaptainAuthCubit` provider above either call site.
Future<void> confirmAndSignOut(BuildContext context) async {
  final confirmed = await CaptainConfirmDialog.show(
    context,
    title: 'تسجيل الخروج',
    message: 'هل أنت متأكد من تسجيل الخروج؟',
    confirmLabel: 'خروج',
    confirmColor: CaptainColors.error,
  );
  if (confirmed) {
    await captainGetIt<CaptainAuthCubit>().signOut();
  }
}

class DriverProfileSignOutButton extends StatelessWidget {
  const DriverProfileSignOutButton({
    super.key,
    this.variant = CaptainButtonVariant.danger,
  });

  final CaptainButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return CaptainButton(
      label: 'تسجيل الخروج',
      icon: Icons.logout_rounded,
      // Material draws the arrow leaving the door rightwards. In Arabic, out
      // is leftwards.
      mirrorIconInRtl: true,
      variant: variant,
      onPressed: () => confirmAndSignOut(context),
    );
  }
}
