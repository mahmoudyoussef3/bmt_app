import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/office_onboarding.dart';

/// The one-time reveal after a successful onboarding.
///
/// Both secrets on this screen are unrecoverable by design. The password was
/// generated in the Edge Function, handed to GoTrue and returned in that single
/// response — it is in no log and no table, and losing it means resetting the
/// account rather than looking it up. The join code lives in `offices.join_code`,
/// which column privileges keep out of reach of every client-tier role; the
/// office reads its own through `office_join_code()`, but the platform admin
/// standing here never sees it again.
///
/// So this occupies the whole screen and takes an explicit dismissal, rather
/// than being a snack bar someone can scroll past.
class OnboardingCredentialsPanel extends StatelessWidget {
  const OnboardingCredentialsPanel({
    super.key,
    required this.result,
    required this.onDone,
  });

  final OfficeOnboardingResult result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                  Icon(Icons.check_circle_rounded, color: scheme.primary, size: 28),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تم إنشاء «${result.officeName}»',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'المكتب جاهز للعمل الآن، ولا يظهر للعملاء حتى تعرضه '
                          'في السوق.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withAlpha(60),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.error.withAlpha(90)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: scheme.error),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        'انسخ البيانات التالية الآن وسلّمها لمسؤول المكتب. '
                        'لن تظهر مرة أخرى بعد إغلاق هذه الصفحة.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              _SecretRow(
                label: 'اسم الدخول',
                value: result.username,
                icon: Icons.person_outline,
              ),
              if (result.hasTemporaryPassword) ...[
                const SizedBox(height: AppSpacing.small),
                _SecretRow(
                  label: 'كلمة المرور المؤقتة',
                  value: result.temporaryPassword!,
                  icon: Icons.key_outlined,
                  emphasise: true,
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.small),
                _InfoRow(
                  label: 'كلمة المرور',
                  value: 'كلمة المرور التي أدخلتها عند الإنشاء.',
                  icon: Icons.key_outlined,
                ),
              ],
              const SizedBox(height: AppSpacing.small),
              _SecretRow(
                label: 'كود انضمام الكباتن',
                value: result.joinCode,
                icon: Icons.qr_code_2_outlined,
              ),
              const SizedBox(height: AppSpacing.small),
              _InfoRow(
                label: 'المعرّف المختصر',
                value: result.slug,
                icon: Icons.link_outlined,
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
        borderRadius: BorderRadius.circular(8),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم نسخ $label')),
              );
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
