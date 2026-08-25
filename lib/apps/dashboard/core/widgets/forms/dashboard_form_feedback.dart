import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/forms/dashboard_form_controller.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// What is still missing, as a list you can act on.
///
/// Shown only after a submit attempt — a form that greets an operator with a
/// wall of red before they have typed anything is worse than one that says
/// nothing. Each entry is a button that scrolls to its field and focuses it,
/// which is the difference between "fix the red fields" and actually being
/// taken to them.
class DashboardFormIssuesBanner extends StatelessWidget {
  const DashboardFormIssuesBanner({
    super.key,
    required this.issues,
    required this.onJumpTo,
    this.message,
  });

  final List<DashboardFormIssue> issues;
  final ValueChanged<String> onJumpTo;

  /// A failure that belongs to no single field — a rejected save, a failed
  /// upload. Rendered above the field list, or alone when there is none.
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty && (message == null || message!.isEmpty)) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final tone = context.status(AppStatusTone.error);
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: tone.tint,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.error.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, color: tone.ink, size: 20),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  message?.isNotEmpty == true
                      ? message!
                      : 'لا يمكن الحفظ بعد — ${issues.length} حقلاً يحتاج إلى تصحيح.',
                  style: text.bodyMedium?.copyWith(
                    color: tone.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (issues.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.xSmall,
              children: [
                for (final issue in issues)
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      Icons.arrow_downward_rounded,
                      size: 15,
                      color: tone.ink,
                    ),
                    label: Text(issue.label),
                    tooltip: issue.message,
                    backgroundColor: scheme.surface,
                    side: BorderSide(color: scheme.error.withAlpha(70)),
                    labelStyle: text.labelMedium?.copyWith(
                      color: tone.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    onPressed: () => onJumpTo(issue.fieldId),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// How far through the mandatory fields the operator is.
///
/// Deliberately counts *passing* required fields, not filled ones — a form
/// that reads 9/9 while a field is still red would be a lie. Reads as a plain
/// line plus a track; it never claims a form is "complete", only that nothing
/// mandatory is outstanding.
class DashboardFormProgress extends StatelessWidget {
  const DashboardFormProgress({
    super.key,
    required this.filled,
    required this.total,
    this.compact = false,
  });

  final int filled;
  final int total;

  /// Drops the caption and thins the track, for a docked action bar.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final done = filled >= total;
    final tone = context.status(
      done ? AppStatusTone.success : AppStatusTone.info,
    );
    final text = Theme.of(context).textTheme;

    final caption = Text(
      done ? 'كل الحقول المطلوبة مكتملة' : 'الحقول المطلوبة: $filled من $total',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (compact ? text.labelMedium : text.bodySmall)?.copyWith(
        color: done ? tone.ink : scheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );

    final track = ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: total == 0 ? 1 : filled / total,
        minHeight: compact ? 4 : 6,
        backgroundColor: scheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(done ? tone.fill : scheme.primary),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        caption,
        const SizedBox(height: AppSpacing.xSmall),
        track,
      ],
    );
  }
}

/// The console's discard-changes prompt.
///
/// One implementation so the wording, the button order and the destructive
/// emphasis are identical wherever an operator is about to lose typing —
/// previously each form carried its own copy, and the trip planner carried
/// none at all.
Future<bool> confirmDiscardChanges(
  BuildContext context, {
  String title = 'تخلٍّ عن التغييرات؟',
  String message = 'لديك بيانات غير محفوظة في هذا النموذج. الخروج الآن يفقدها.',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: Theme.of(ctx).colorScheme.error,
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('متابعة التعديل'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('خروج بدون حفظ'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
