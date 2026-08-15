import 'package:bmt_app/core/theme/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/users_cubit.dart';
import '../cubit/users_state.dart';
import 'staff_account_form.dart';

/// Creating a staff login, from the «إضافة مستخدم» button in the module header.
///
/// The dialog stays open across a failed submission on purpose. [UsersCubit.createUser]
/// answers with per-field errors when a username is rejected, and closing on submit
/// would throw them away and leave the owner with a snackbar and an empty form to
/// retype. It closes on exactly one signal: [UsersCredentialsIssued], the state that
/// carries the one-time password — which the screen behind renders full width, because
/// that password cannot be read back from anywhere.
Future<void> showStaffAccountDialog(BuildContext context) {
  final cubit = context.read<UsersCubit>();

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider<UsersCubit>.value(
      value: cubit,
      child: const _StaffAccountDialog(),
    ),
  );
}

class _StaffAccountDialog extends StatelessWidget {
  const _StaffAccountDialog();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsersCubit, UsersState>(
      listenWhen: (_, current) => current is UsersCredentialsIssued,
      listener: (context, _) => Navigator.of(context).pop(),
      builder: (context, state) {
        final isSubmitting = switch (state) {
          UsersLoaded(:final isSubmitting) => isSubmitting,
          _ => false,
        };
        final fieldErrors = switch (state) {
          UsersActionFailure(:final fieldErrors) => fieldErrors,
          UsersLoaded(:final fieldErrors) => fieldErrors,
          _ => const <String, String>{},
        };
        final failure = state is UsersActionFailure ? state.message : null;

        return AlertDialog(
          title: const Text('إضافة مستخدم للوحة التحكم'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'يسجّل الموظف الدخول باسم المستخدم وكلمة المرور من نفس شاشة '
                    'الدخول. الحساب يخص مكتبك وحده ولا يرى بيانات أي مكتب آخر.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  if (failure != null) ...[
                    const SizedBox(height: AppSpacing.medium),
                    _FailureBanner(message: failure),
                  ],
                  const SizedBox(height: AppSpacing.large),
                  StaffAccountForm(
                    isSubmitting: isSubmitting,
                    fieldErrors: fieldErrors,
                    onSubmit: context.read<UsersCubit>().createUser,
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

/// The refusal, inside the dialog rather than behind it.
///
/// A snackbar would be posted to the scaffold under the barrier, where a modal dialog
/// hides it — so the owner would see the form simply do nothing.
class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withAlpha(70),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.error.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: scheme.error),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
