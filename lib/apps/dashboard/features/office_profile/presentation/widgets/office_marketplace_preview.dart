import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// The office's own card, drawn the way a passenger meets it in the Client
/// app's directory — from the values in the form, not from the saved row.
///
/// The office is the one party that never sees its own shopfront: the platform
/// console renders `public_offices`, the rider app renders the card, and the
/// operator editing the fields sees only labelled inputs. So a blank
/// description reads as an empty field here rather than as the thin, wordless
/// card it actually produces in the directory.
///
/// It is a **preview, not the component** — the rider app draws it with its own
/// palette and typography ([ClientCard], `OfficeCardBody`), which do not exist
/// inside the console's theme. It is faithful in content and order, which is
/// what the operator is deciding about, and says so under the header rather
/// than implying pixel fidelity.
class OfficeMarketplacePreview extends StatelessWidget {
  const OfficeMarketplacePreview({
    super.key,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.serviceAreas,
    required this.rating,
    required this.ratingsCount,
    required this.isListed,
  });

  final String name;
  final String description;
  final String logoUrl;
  final List<String> serviceAreas;
  final double rating;
  final int ratingsCount;

  /// Drives the footnote only. A preview of a card nobody can currently reach
  /// has to say so, or it reads as a promise.
  final bool isListed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final trimmedName = name.trim();
    final trimmedDescription = description.trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: DashboardColors.nested(context),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.phone_iphone_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xSmall),
              Expanded(
                child: Text(
                  'معاينة بطاقتك في تطبيق العملاء',
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: DashboardColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PreviewLogo(url: logoUrl),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trimmedName.isEmpty ? 'اسم المكتب' : trimmedName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: trimmedName.isEmpty
                                  ? scheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _RatingLine(rating: rating, count: ratingsCount),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  trimmedDescription.isEmpty
                      ? 'بدون وصف — البطاقة تظهر للعملاء بلا أي شرح للخدمة.'
                      : trimmedDescription,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    height: 1.6,
                    color: trimmedDescription.isEmpty
                        ? context.status(AppStatusTone.warning).ink
                        : scheme.onSurfaceVariant,
                  ),
                ),
                if (serviceAreas.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.small),
                  Wrap(
                    spacing: AppSpacing.xSmall,
                    runSpacing: AppSpacing.xSmall,
                    children: [
                      for (final area in serviceAreas.take(4))
                        Container(
                          padding: AppSpacing.chip,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withAlpha(
                              120,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusSmall,
                            ),
                          ),
                          child: Text(
                            area,
                            style: text.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (serviceAreas.length > 4)
                        Text(
                          '+${serviceAreas.length - 4}',
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            isListed
                ? 'تظهر التعديلات للعملاء بعد الضغط على حفظ.'
                : 'مكتبك غير معروض في السوق حالياً، فلا يرى العملاء هذه البطاقة بعد.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PreviewLogo extends StatelessWidget {
  const _PreviewLogo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: url.trim().isEmpty
          ? Icon(
              Icons.storefront_outlined,
              size: 20,
              color: scheme.onSurfaceVariant,
            )
          : Image.network(
              url.trim(),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.broken_image_outlined,
                size: 20,
                color: scheme.error,
              ),
            ),
    );
  }
}

/// The rating line as the directory draws it: a figure only when the office has
/// actually been rated. A "0.0 ★" on a new office is a bad review it never got.
class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (count <= 0) {
      return Text(
        'لا توجد تقييمات بعد',
        style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
      );
    }
    final tone = context.status(AppStatusTone.warning);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 15, color: tone.accent),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: text.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
