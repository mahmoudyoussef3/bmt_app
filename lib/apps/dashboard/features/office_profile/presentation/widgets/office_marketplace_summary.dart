import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/office_profile.dart';

/// Platform-owned facts about the office: listing status, reputation, and how
/// complete its marketplace card is. All read-only — nothing here is a field
/// the office fills in, which is exactly why it sits apart from the form.
class OfficeMarketplaceSummary extends StatelessWidget {
  const OfficeMarketplaceSummary({super.key, required this.profile});

  final OfficeProfile profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final missing = profile.missingMarketplaceFields;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardKpiGrid(
            maxColumns: 3,
            children: [
              
              DashboardKpiCard(
                label: 'حالة الظهور في السوق',
                value: profile.listingLabel,
                detail: profile.isListed
                    ? 'يظهر المكتب في دليل العملاء'
                    : 'لا يظهر المكتب للعملاء حالياً',
                icon: profile.isListed
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: profile.isListed
                    ? scheme.primary
                    : (profile.isDraft ? scheme.tertiary : scheme.error),
              ),
              DashboardKpiCard(
                label: 'تقييم المكتب',
                value: profile.hasRatings
                    ? profile.rating.toStringAsFixed(1)
                    : '—',
                detail: profile.hasRatings
                    ? '${profile.ratingsCount} تقييم'
                    : 'لا توجد تقييمات بعد',
                icon: Icons.star_rate_rounded,
                color: scheme.tertiary,
              ),
              DashboardKpiCard(
                label: 'اكتمال الملف',
                value: '${((4 - missing.length) / 4 * 100).round()}%',
                detail: missing.isEmpty
                    ? 'كل البيانات مكتملة'
                    : 'ينقص: ${missing.join('، ')}',
                icon: missing.isEmpty
                    ? Icons.verified_outlined
                    : Icons.error_outline_rounded,
                color: missing.isEmpty ? scheme.primary : scheme.error,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          _Notice(
            icon: profile.isListed
                ? Icons.storefront_outlined
                : (profile.isDraft
                      ? Icons.hourglass_top_rounded
                      : Icons.visibility_off_outlined),
            color: profile.isListed
                ? scheme.primary
                : (profile.isDraft ? scheme.tertiary : scheme.error),
            message: profile.isListed
                ? profile.listingExplanation
                
                : '${profile.listingExplanation} '
                      'النشر والسحب من السوق قرار إداري على مستوى منصة EWT ولا يتم من هنا.',
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
