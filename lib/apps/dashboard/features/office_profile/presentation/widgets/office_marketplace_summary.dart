import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/office_profile.dart';

/// Platform-owned facts about the office: is it working, can passengers see it,
/// how is it rated, and what is still missing from its card.
///
/// All read-only — nothing here is a field the office fills in, which is
/// exactly why it sits apart from the form. Its shape follows the one thing
/// operators most often misread: **there are two status axes, not one.** An
/// office can be perfectly active and still invisible, so the two are drawn as
/// two separate panels with their own explanations rather than as one "status"
/// figure that has to mean both.
class OfficeMarketplaceSummary extends StatelessWidget {
  const OfficeMarketplaceSummary({
    super.key,
    required this.profile,
    this.onJumpToField,
  });

  final OfficeProfile profile;

  /// Takes the operator to the field a checklist item names. Absent when no
  /// form is mounted (the read-only view), and the items then render as plain
  /// rows rather than as buttons that would go nowhere.
  final Future<void> Function(String fieldId)? onJumpToField;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final operational = _OperationalStatusPanel(profile: profile);
              final listing = _ListingStatusPanel(profile: profile);
              if (constraints.maxWidth < 760) {
                return Column(
                  children: [
                    operational,
                    const SizedBox(height: AppSpacing.medium),
                    listing,
                  ],
                );
              }
              // The two axes carry very different amounts of text; matching
              // their heights is what makes them read as two halves of one
              // statement rather than a panel with a footnote beside it.
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: operational),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(flex: 2, child: listing),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.medium),
          _CompletenessPanel(profile: profile, onJumpToField: onJumpToField),
        ],
      ),
    );
  }
}

/// Axis one: can the office *work*? Staff sign-in, captain recruitment, trips.
class _OperationalStatusPanel extends StatelessWidget {
  const _OperationalStatusPanel({required this.profile});

  final OfficeProfile profile;

  @override
  Widget build(BuildContext context) {
    final tone = context.status(switch (profile.status) {
      'active' => AppStatusTone.success,
      'paused' => AppStatusTone.warning,
      'archived' => AppStatusTone.neutral,
      _ => AppStatusTone.error,
    });

    return _Panel(
      tone: tone,
      icon: switch (profile.status) {
        'active' => Icons.play_circle_outline_rounded,
        'paused' => Icons.pause_circle_outline_rounded,
        'archived' => Icons.inventory_2_outlined,
        _ => Icons.block_rounded,
      },
      label: 'حالة التشغيل',
      value: profile.statusLabel,
      body: switch (profile.status) {
        'active' =>
          'المكتب يعمل: الحسابات تسجّل الدخول، والرحلات والحجوزات تسير.',
        'paused' =>
          'المكتب متوقف مؤقتاً. راجع إدارة المنصة لاستئناف التشغيل الكامل.',
        'archived' => 'المكتب مؤرشف ولم يعد ضمن المكاتب العاملة على المنصة.',
        _ => 'المكتب موقوف من إدارة المنصة. تواصل معها لمعرفة السبب.',
      },
      trailing: _RatingBadge(profile: profile),
    );
  }
}

/// Axis two: can *passengers see it*? A different question with a different
/// owner — the office cannot publish or withdraw itself, so the panel says who
/// can, and what would make the office publishable.
class _ListingStatusPanel extends StatelessWidget {
  const _ListingStatusPanel({required this.profile});

  final OfficeProfile profile;

  @override
  Widget build(BuildContext context) {
    final tone = context.status(
      profile.isListed
          ? AppStatusTone.success
          : (profile.isDraft ? AppStatusTone.info : AppStatusTone.warning),
    );
    final blockers = profile.listingBlockers;

    return _Panel(
      tone: tone,
      icon: profile.isListed
          ? Icons.visibility_outlined
          : (profile.isDraft
                ? Icons.hourglass_top_rounded
                : Icons.visibility_off_outlined),
      label: 'الظهور للعملاء',
      value: profile.listingLabel,
      body: profile.listingExplanation,
      footer: profile.isListed
          ? null
          : _ListingRequirements(blockers: blockers),
    );
  }
}

/// What EWT requires before it will publish an office, and which of those the
/// office has met — so "you are not listed" is never the end of the sentence.
class _ListingRequirements extends StatelessWidget {
  const _ListingRequirements({required this.blockers});

  final List<String> blockers;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final met = blockers.isEmpty;
    final tone = context.status(
      met ? AppStatusTone.success : AppStatusTone.warning,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              met ? Icons.check_circle_outline_rounded : Icons.rule_rounded,
              size: 16,
              color: tone.ink,
            ),
            const SizedBox(width: AppSpacing.xSmall),
            Expanded(
              child: Text(
                met
                    ? 'مكتبك مستوفٍ لشروط النشر (حالة نشطة، وصف، مناطق خدمة). '
                          'قرار العرض في السوق يبقى لإدارة منصة EWT.'
                    : 'شروط النشر التي تنقصك: ${blockers.join('، ')}. '
                          'بعد استيفائها يصبح المكتب قابلاً للنشر، والقرار النهائي '
                          'لإدارة منصة EWT.',
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The office's reputation, kept beside its operational state because both are
/// facts *about* the office rather than fields on its card.
class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.profile});

  final OfficeProfile profile;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tone = context.status(AppStatusTone.warning);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 18, color: tone.accent),
            const SizedBox(width: 2),
            Text(
              profile.hasRatings ? profile.rating.toStringAsFixed(1) : '—',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        Text(
          profile.hasRatings
              ? '${profile.ratingsCount} تقييم'
              : 'لا تقييمات بعد',
          style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// The marketplace card's four fields, as a checklist that can be acted on.
///
/// A percentage is a statistic; this is a to-do list — each unmet item is a
/// button that scrolls to the field it names and focuses it. The percentage is
/// kept as the headline because it is what the operator glances at, and the
/// items underneath are what they do about it.
class _CompletenessPanel extends StatelessWidget {
  const _CompletenessPanel({required this.profile, this.onJumpToField});

  final OfficeProfile profile;
  final Future<void> Function(String fieldId)? onJumpToField;

  static const _fields = <String, String>{
    'وصف المكتب': 'description',
    'شعار المكتب': 'logo',
    'رقم التواصل': 'phone',
    'مناطق الخدمة': 'areas',
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final missing = profile.missingMarketplaceFields;
    final done = _fields.length - missing.length;
    final complete = missing.isEmpty;
    final tone = context.status(
      complete ? AppStatusTone.success : AppStatusTone.warning,
    );

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
                complete
                    ? Icons.verified_outlined
                    : Icons.checklist_rtl_rounded,
                size: 20,
                color: tone.ink,
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  'اكتمال بطاقة السوق',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '$done من ${_fields.length}',
                style: text.labelLarge?.copyWith(
                  color: tone.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: done / _fields.length,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                complete ? tone.fill : scheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              for (final entry in _fields.entries)
                _ChecklistItem(
                  label: entry.key,
                  filled: !missing.contains(entry.key),
                  onTap: onJumpToField == null
                      ? null
                      : () => onJumpToField!(entry.value),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            complete
                ? 'بطاقتك مكتملة. الوصف والشعار ومناطق الخدمة هي ما يجعل العميل '
                      'يختار مكتبك من بين المكاتب المعروضة.'
                : 'اضغط على أي بند ناقص للانتقال إلى حقله في النموذج بالأسفل.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.label, required this.filled, this.onTap});

  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = context.status(
      filled ? AppStatusTone.success : AppStatusTone.warning,
    );
    final text = Theme.of(context).textTheme;

    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.xSmall,
      ),
      decoration: BoxDecoration(
        color: tone.tint,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: tone.ink.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filled ? Icons.check_rounded : Icons.add_rounded,
            size: 16,
            color: tone.ink,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: text.labelMedium?.copyWith(
              color: tone.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (filled || onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: content,
    );
  }
}

/// One status axis, drawn as a tinted panel: what the state is called, what it
/// means in practice, and — when there is one — what to do about it.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.tone,
    required this.icon,
    required this.label,
    required this.value,
    required this.body,
    this.trailing,
    this.footer,
  });

  final AppStatusStyle tone;
  final IconData icon;
  final String label;
  final String value;
  final String body;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: tone.tint,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: tone.ink.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: tone.ink),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      value,
                      style: text.titleMedium?.copyWith(
                        color: tone.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(body, style: text.bodySmall?.copyWith(height: 1.7)),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.small),
            Divider(color: tone.ink.withAlpha(40), height: 1),
            const SizedBox(height: AppSpacing.small),
            footer!,
          ],
        ],
      ),
    );
  }
}
