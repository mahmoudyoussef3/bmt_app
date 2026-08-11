import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_confirm_dialog.dart';
import 'package:bmt_app/apps/captain/features/auth/presentation/cubit/captain_auth_cubit.dart';

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
      mirrorIconInRtl: true,
      variant: variant,
      onPressed: () => confirmAndSignOut(context),
    );
  }
}
