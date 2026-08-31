import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/office_profile.dart';

/// The office's captain join code, treated as the credential it is.
///
/// A captain cannot apply to an office without it (migration 20260721100200
/// made `submit_captain_request` require the code), and until this card existed
/// the office held a credential it could not read. Everything about the card
/// follows from "credential", not "field":
///
/// * **Masked by default**, revealed deliberately. The console is often open on
///   a screen other people can see; a code that recruits drivers into your
///   office should not sit permanently readable on it.
/// * **Copy works while masked** — sharing the code is the whole point, and it
///   never requires showing it first.
/// * **Rotation is offered here**, behind a confirmation that says what breaks:
///   `office_rotate_join_code()` invalidates the old value platform-wide, which
///   is the only way an office whose code reached the wrong driver can take it
///   back.
/// * **A failed read says so.** "لم يُصدر كود" and "تعذّر القراءة" are different
///   facts, and an office told the first when the second happened goes looking
///   for a code that already exists.
class OfficeJoinCodeCard extends StatefulWidget {
  const OfficeJoinCodeCard({
    super.key,
    required this.profile,
    required this.canRotate,
    required this.isRotating,
    required this.onRotate,
    required this.onRetry,
  });

  final OfficeProfile profile;

  /// Owner only — the RPC raises `dashboard_admin_required` for anyone else, so
  /// the button is absent rather than present and refused.
  final bool canRotate;

  final bool isRotating;
  final VoidCallback onRotate;

  /// Re-reads the office, used when the code itself could not be fetched.
  final VoidCallback onRetry;

  @override
  State<OfficeJoinCodeCard> createState() => _OfficeJoinCodeCardState();
}

class _OfficeJoinCodeCardState extends State<OfficeJoinCodeCard> {
  bool _revealed = false;

  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: widget.profile.joinCode));
    messenger.showSnackBar(
      const SnackBar(content: Text('تم نسخ كود الانضمام')),
    );
  }

  Future<void> _confirmRotate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.autorenew_rounded,
          color: Theme.of(ctx).colorScheme.error,
        ),
        title: const Text('تدوير كود الانضمام؟'),
        content: const Text(
          'سيصدر كود جديد ويتوقف الكود الحالي عن العمل فوراً. '
          'أي كابتن يحمل الكود القديم لن يستطيع التقديم للانضمام لمكتبك، '
          'وستحتاج إلى مشاركة الكود الجديد مع السائقين الذين تثق بهم.\n\n'
          'طلبات الانضمام المقدَّمة بالفعل لا تتأثر.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.autorenew_rounded),
            label: const Text('إصدار كود جديد'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _revealed = true);
      widget.onRotate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final profile = widget.profile;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(22),
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                ),
                child: Icon(Icons.vpn_key_outlined, color: scheme.primary),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'كود انضمام الكباتن',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'يطلب تطبيق الكابتن هذا الكود عند التقديم للانضمام لمكتبك. '
                      'شاركه مع السائقين الذين تثق بهم فقط — الطلب يظل بحاجة '
                      'لموافقتك بعد ذلك.',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          if (profile.joinCodeReadFailed)
            _CodeNotice(
              tone: context.status(AppStatusTone.error),
              icon: Icons.wifi_off_rounded,
              message:
                  'تعذّر قراءة كود الانضمام الآن. الكود موجود ولم يتغيّر — '
                  'أعد المحاولة.',
              action: TextButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة المحاولة'),
              ),
            )
          else if (!profile.hasJoinCode)
            _CodeNotice(
              tone: context.status(AppStatusTone.warning),
              icon: Icons.key_off_rounded,
              message:
                  'لم يُصدر كود لهذا المكتب بعد. '
                  '${widget.canRotate ? 'اضغط «إصدار كود» لإنشاء واحد.' : 'تواصل مع إدارة المنصة لإصداره.'}',
              action: widget.canRotate
                  ? FilledButton.tonalIcon(
                      onPressed: widget.isRotating ? null : widget.onRotate,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('إصدار كود'),
                    )
                  : null,
            )
          else
            _CodeRow(
              code: profile.joinCode,
              revealed: _revealed,
              isRotating: widget.isRotating,
              canRotate: widget.canRotate,
              onToggleReveal: () => setState(() => _revealed = !_revealed),
              onCopy: _copy,
              onRotate: _confirmRotate,
            ),
          if (profile.hasJoinCode && !profile.joinCodeReadFailed) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              _rotationLine(profile.joinCodeRotatedAt),
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  /// Says when the code last changed, and nothing at all when the database did
  /// not report it — an office running against a schema without
  /// `office_join_code_info()` gets silence rather than an invented "never".
  String _rotationLine(DateTime? rotatedAt) {
    if (rotatedAt == null) {
      return 'شارك الكود بشكل خاص. إن وصل لشخص غير موثوق، دوّره فوراً.';
    }
    final days = DateTime.now().difference(rotatedAt).inDays;
    final ago = switch (days) {
      < 1 => 'اليوم',
      < 30 => 'قبل $days يوماً',
      < 365 => 'قبل ${(days / 30).round()} أشهر',
      _ => 'قبل ${(days / 365).round()} سنة',
    };
    return 'آخر تدوير: $ago';
  }
}

/// The code itself, plus the three things an operator does with it.
class _CodeRow extends StatelessWidget {
  const _CodeRow({
    required this.code,
    required this.revealed,
    required this.isRotating,
    required this.canRotate,
    required this.onToggleReveal,
    required this.onCopy,
    required this.onRotate,
  });

  final String code;
  final bool revealed;
  final bool isRotating;
  final bool canRotate;
  final VoidCallback onToggleReveal;
  final Future<void> Function() onCopy;
  final Future<void> Function() onRotate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final warning = context.status(AppStatusTone.warning);

    return Wrap(
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onToggleReveal,
                visualDensity: VisualDensity.compact,
                tooltip: revealed ? 'إخفاء الكود' : 'إظهار الكود',
                icon: Icon(
                  revealed
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.xSmall),
              if (isRotating)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  // Masked with one bullet per character, so the length of the
                  // code is still obvious while its value is not.
                  //
                  // No pinned direction: the alphabet is `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`
                  // (migration 20260721100200), so the code is one strong-LTR
                  // run that bidi already lays out left to right inside the
                  // RTL page.
                  revealed ? code : '•' * code.length,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: revealed ? 4 : 6,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: isRotating ? null : () => onCopy(),
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('نسخ الكود'),
        ),
        if (canRotate)
          FilledButton.tonalIcon(
            onPressed: isRotating ? null : () => onRotate(),
            style: FilledButton.styleFrom(
              backgroundColor: warning.tint,
              foregroundColor: warning.ink,
            ),
            icon: isRotating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.autorenew_rounded, size: 18),
            label: Text(isRotating ? 'جارٍ الإصدار...' : 'تدوير الكود'),
          ),
      ],
    );
  }
}

/// The card's non-code states: nothing issued, or nothing readable.
class _CodeNotice extends StatelessWidget {
  const _CodeNotice({
    required this.tone,
    required this.icon,
    required this.message,
    this.action,
  });

  final AppStatusStyle tone;
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: tone.tint,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: tone.ink.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: tone.ink),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tone.ink, height: 1.6),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
