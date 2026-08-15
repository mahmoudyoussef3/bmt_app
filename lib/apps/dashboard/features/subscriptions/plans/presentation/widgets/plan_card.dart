import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/subscription_plan.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

class PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const PlanCard({
    super.key,
    required this.plan,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activate = plan.status != PlanStatus.active;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan.title, style: theme.textTheme.titleLarge),
              ),
              _statusChip(context),
            ],
          ),
          if (plan.subtitle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xSmall),
            Text(plan.subtitle, style: theme.textTheme.bodyMedium),
          ],
          if (plan.descriptionAr.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xSmall),
            Text(
              plan.descriptionAr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Divider(height: AppSpacing.large),
          Wrap(
            spacing: AppSpacing.large,
            runSpacing: AppSpacing.small,
            children: [
              _info(context, 'السعر', '${plan.price.toStringAsFixed(0)} ج.م'),
              _info(context, 'المدة', '${plan.days} يوم'),
              _info(context, 'عدد الرحلات', '${plan.tripsCount}'),
              if (plan.discountPercent > 0)
                _info(context, 'الخصم', '%${plan.discountPercent}'),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              spacing: AppSpacing.small,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('تعديل'),
                ),
                OutlinedButton.icon(
                  onPressed: onToggleStatus,
                  icon: Icon(
                    activate ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 18,
                  ),
                  label: Text(activate ? 'تفعيل' : 'إيقاف'),
                ),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('حذف'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.status(AppStatusTone.error).ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context) {
    final color = switch (plan.status) {
      PlanStatus.active => context.status(AppStatusTone.success).ink,
      PlanStatus.paused => context.status(AppStatusTone.warning).ink,
      PlanStatus.archived => context.status(AppStatusTone.neutral).ink,
    };
    return StatusChip(
      label: plan.status.label,
      color: color.withAlpha(28),
      textColor: color,
    );
  }

  Widget _info(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
