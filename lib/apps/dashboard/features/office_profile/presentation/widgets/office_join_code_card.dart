import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/office_profile.dart';

/// The office's captain join code.
///
/// A captain cannot apply to an office without it (migration
/// 20260721100200 made `submit_captain_request` require the code), and until
/// now the code was generated in the database with no surface that showed it —
/// leaving the office holding a credential it could not read. This card is that
/// surface: display and copy only, because the column is uniquely indexed
/// platform-wide and rotating it safely belongs in an RPC, not in an update
/// statement the dashboard composes.
class OfficeJoinCodeCard extends StatelessWidget {
  const OfficeJoinCodeCard({super.key, required this.profile});

  final OfficeProfile profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasCode = profile.joinCode.trim().isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key_outlined, color: scheme.primary),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  'كود انضمام الكباتن',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            'يطلب تطبيق الكابتن هذا الكود عند التقديم للانضمام لمكتبك. '
            'شاركه مع السائقين الذين تثق بهم فقط — الطلب يظل بحاجة لموافقتك بعد ذلك.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.medium),
          if (!hasCode)
            Text(
              'لم يُصدر كود لهذا المكتب بعد.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.error),
            )
          else
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.large,
                    vertical: AppSpacing.small,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withAlpha(16),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                    border: Border.all(color: scheme.primary.withAlpha(60)),
                  ),
                  child: Text(
                    profile.joinCode,
                    // Read aloud and typed by hand, so it is spaced and
                    // monospaced rather than set in the body font.
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(
                      ClipboardData(text: profile.joinCode),
                    );
                    messenger.showSnackBar(
                      const SnackBar(content: Text('تم نسخ كود الانضمام')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('نسخ الكود'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
