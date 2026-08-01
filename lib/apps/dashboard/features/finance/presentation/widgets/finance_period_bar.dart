import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/finance_entities.dart';
import 'finance_format.dart';

/// The single control that scopes the whole module. It lives in the module
/// header, above the tabs, because every tab answers the same question for the
/// same window — a per-tab date picker is how two figures on one screen end up
/// meaning two different periods.
class FinancePeriodBar extends StatelessWidget {
  final FinancePeriod selected;
  final ValueChanged<FinancePeriod> onSelected;
  final DateTime loadedAt;
  final bool capReached;

  const FinancePeriodBar({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.loadedAt,
    this.capReached = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.small),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xSmall),
                  Text(
                    'فترة التقرير',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            for (final period in FinancePeriod.values)
              ChoiceChip(
                label: Text(period.label),
                selected: selected == period,
                avatar: selected == period
                    ? const Icon(Icons.check_rounded, size: 16)
                    : null,
                onSelected: (isSelected) {
                  if (isSelected) onSelected(period);
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.xSmall,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'آخر تحديث: ${FinanceFormat.time(loadedAt)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(
              'التحقق من إثباتات الدفع يتم في قسم الحجوزات',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (capReached) _CapNotice(rowCap: FinanceLedger.rowCap),
          ],
        ),
      ],
    );
  }
}

/// The ledger is capped, and a finance screen that silently drops the oldest
/// movements is worse than one that admits the horizon.
class _CapNotice extends StatelessWidget {
  final int rowCap;

  const _CapNotice({required this.rowCap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.xSmall,
      ),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withAlpha(90),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: scheme.onSurface),
          const SizedBox(width: AppSpacing.xSmall),
          Text(
            'يعرض أحدث ${FinanceFormat.count(rowCap)} معاملة',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
