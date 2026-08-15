import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/staff_account.dart';

/// The one-time reveal after an account is created or its password reset.
///
/// The password on this screen is unrecoverable by design. It was generated inside the
/// Edge Function, handed to GoTrue and returned in that single response — it is in no
/// log and no table, and losing it means resetting the account rather than looking it
/// up.
///
/// So this occupies the whole screen and takes an explicit dismissal, rather than being
/// a snack bar someone can scroll past. The same shape platform onboarding uses for the
/// same reason.
class StaffCredentialsPanel extends StatelessWidget {
  const StaffCredentialsPanel({
    super.key,
    required this.credentials,
    required this.onDone,
  });

  final StaffCredentials credentials;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isReset = credentials.isReset;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: scheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isReset
                              ? 'تم تغيير كلمة المرور'
                              : 'تم إنشاء حساب «${credentials.username}»',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isReset
                              ? 'كلمة المرور القديمة لم تعد تعمل.'
                              : 'يمكن للموظف تسجيل الدخول الآن من شاشة الدخول '
                                    'نفسها.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              if (credentials.hasTemporaryPassword)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withAlpha(60),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                    border: Border.all(color: scheme.error.withAlpha(90)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: scheme.error),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: Text(
                          'انسخ البيانات التالية الآن وسلّمها للموظف. لن تظهر '
                          'مرة أخرى بعد إغلاق هذه الصفحة.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              if (credentials.hasTemporaryPassword)
                const SizedBox(height: AppSpacing.large),
              _SecretRow(
                label: 'اسم الدخول',
                value: credentials.username,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: AppSpacing.small),
              if (credentials.hasTemporaryPassword)
                _SecretRow(
                  label: 'كلمة المرور',
                  value: credentials.temporaryPassword!,
                  icon: Icons.key_outlined,
                  emphasise: true,
                )
              else
                _InfoRow(
                  label: 'كلمة المرور',
                  value: 'كلمة المرور التي أدخلتها.',
                  icon: Icons.key_outlined,
                ),
              const SizedBox(height: AppSpacing.large),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  onPressed: onDone,
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('حفظت البيانات — إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecretRow extends StatelessWidget {
  const _SecretRow({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: emphasise
            ? scheme.primaryContainer.withAlpha(70)
            : scheme.surfaceContainerHighest.withAlpha(70),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SelectableText(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'نسخ',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('تم نسخ $label')));
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.small),
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
