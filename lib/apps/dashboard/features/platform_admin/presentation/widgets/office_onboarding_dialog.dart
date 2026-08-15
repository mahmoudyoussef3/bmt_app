import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/platform_admin_cubit.dart';
import '../cubit/platform_admin_state.dart';
import 'office_onboarding_form.dart';

/// Creating an office, where every other creation in this console happens.
///
/// The form used to live permanently on the page — folded, between the platform
/// overview and the office filters — as standing chrome for something done a
/// handful of times a year. It is a dialog now, reached from the one «مكتب جديد»
/// button in the page header.
///
/// The dialog stays open across a failed submission on purpose. `onboard`
/// answers with per-field errors when the server rejects a slug or a username,
/// and closing on submit would throw them away and leave the operator with a
/// snackbar and an empty form to retype. It closes on exactly one signal:
/// [PlatformAdminOnboarded], the state that carries the one-time password —
/// which the screen behind renders full width, because that password cannot be
/// read back from anywhere.
Future<void> showOfficeOnboardingDialog(BuildContext context) {
  final cubit = context.read<PlatformAdminCubit>();

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider<PlatformAdminCubit>.value(
      value: cubit,
      child: const _OfficeOnboardingDialog(),
    ),
  );
}

class _OfficeOnboardingDialog extends StatelessWidget {
  const _OfficeOnboardingDialog();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlatformAdminCubit, PlatformAdminState>(
      listenWhen: (_, current) => current is PlatformAdminOnboarded,
      listener: (context, _) => Navigator.of(context).pop(),
      builder: (context, state) {
        final isSubmitting = switch (state) {
          PlatformAdminLoaded(:final isSubmitting) => isSubmitting,
          _ => false,
        };
        final fieldErrors = switch (state) {
          PlatformAdminActionFailure(:final fieldErrors) => fieldErrors,
          PlatformAdminLoaded(:final fieldErrors) => fieldErrors,
          _ => const <String, String>{},
        };

        return AlertDialog(
          title: const Text('إضافة مكتب جديد'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'يُنشأ المكتب مباشرة مع حساب مسؤوله الأول، ولا يظهر '
                    'للعملاء حتى تعرضه في السوق.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OfficeOnboardingForm(
                    embedded: true,
                    isSubmitting: isSubmitting,
                    fieldErrors: fieldErrors,
                    onSubmit: context.read<PlatformAdminCubit>().onboard,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }
}
