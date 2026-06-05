import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusChip({required this.label, this.color, super.key});

  const StatusChip.semantic({required this.label, super.key}) : color = null;

  @override
  Widget build(BuildContext context) {
    final statusColor = color ?? _semanticColor(context, label);
    return Container(
      padding: AppSpacing.chip,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _semanticColor(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      'نشطة' || 'مقبول' || 'مكتملة' || 'تم الحل' => scheme.primary,
      'متأخرة' || 'عاجل' || 'مرفوض' || 'ملغاة' => scheme.error,
      'معلقة' || 'قيد المراجعة' || 'جديدة' => scheme.tertiary,
      _ => scheme.onSurfaceVariant,
    };
  }
}
