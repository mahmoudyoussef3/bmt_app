import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_live_sync_chip.dart';

import '../../domain/entities/captain_day_summary.dart';

/// Every assigned trip is done and no new one has arrived yet.
///
/// This takes the place of the focus card, so it has to carry the same weight:
/// it closes the day with the captain's own numbers rather than leaving a
/// screen of finished trips with nothing to act on, then hands the waiting back
/// to operations with the same "it arrives here on its own" promise the
/// awaiting-trips view makes.
class CaptainDayCompleteView extends StatelessWidget {
  const CaptainDayCompleteView({
    super.key,
    required this.summary,
    required this.onRefresh,
    this.isRefreshing = false,
  });

  final CaptainDaySummary summary;
  final Future<void> Function() onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CompletionHero(summary: summary),
        const SizedBox(height: CaptainDesignTokens.s16),
        _NextAssignmentCard(onRefresh: onRefresh, isRefreshing: isRefreshing),
      ],
    );
  }
}

/// The celebration itself, in the focus card's gradient language so a finished
/// day reads as an achievement rather than an absence.
class _CompletionHero extends StatelessWidget {
  const _CompletionHero({required this.summary});

  final CaptainDaySummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Runs from the "done" end of the palette into the brand anchor: still
        // one blue family, but visibly not the focus card's live-trip blue.
        gradient: const LinearGradient(
          colors: [CaptainColors.primaryDeep, CaptainColors.primary],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: CaptainDesignTokens.br24,
        boxShadow: [
          BoxShadow(
            color: CaptainColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: CaptainDesignTokens.br24,
        child: Stack(
          children: [
            const PositionedDirectional(top: -48, end: -36, child: _Glow(180)),
            const PositionedDirectional(
              bottom: -56,
              start: -44,
              child: _Glow(150),
            ),
            Padding(
              padding: const EdgeInsets.all(CaptainDesignTokens.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _CompletionSeal(),
                      const SizedBox(width: CaptainDesignTokens.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'اكتمل جدول اليوم',
                              style: CaptainTypography.labelMedium(context)
                                  .copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'أحسنت، أنهيت رحلات اليوم',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: CaptainTypography.titleLarge(context)
                                  .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CaptainDesignTokens.s20),
                  _CompletionMetrics(summary: summary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A soft blob of light behind the hero content, for depth on a flat gradient.
class _Glow extends StatelessWidget {
  const _Glow(this.size);

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.07),
      ),
    );
  }
}

/// The check mark, stamped on once when the finished day first appears.
class _CompletionSeal extends StatelessWidget {
  const _CompletionSeal();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: const Icon(Icons.check_rounded, size: 30, color: Colors.white),
      ),
    );
  }
}

/// What the captain actually did today — the reason this screen is a reward and
/// not just an empty state.
class _CompletionMetrics extends StatelessWidget {
  const _CompletionMetrics({required this.summary});

  final CaptainDaySummary summary;

  @override
  Widget build(BuildContext context) {
    final lastArrival = summary.lastArrival;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CaptainDesignTokens.s12,
        vertical: CaptainDesignTokens.s16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: CaptainDesignTokens.br16,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _Metric(
            icon: Icons.route_rounded,
            value: '${summary.totalTrips}',
            label: 'رحلة مكتملة',
          ),
          const _MetricDivider(),
          _Metric(
            icon: Icons.people_alt_rounded,
            value: '${summary.boarded}',
            label: 'راكب نُقل',
          ),
          if (lastArrival != null) ...[
            const _MetricDivider(),
            _Metric(
              icon: Icons.flag_rounded,
              value: CaptainFormats.clock(lastArrival),
              label: 'آخر وصول',
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.75)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: CaptainTypography.titleLarge(
                context,
              ).copyWith(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: CaptainTypography.labelSmall(context).copyWith(
              color: Colors.white.withValues(alpha: 0.80),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}

/// Where the day goes next. Without this the captain is left to guess whether
/// finishing the schedule means the app is done talking to them.
class _NextAssignmentCard extends StatelessWidget {
  const _NextAssignmentCard({
    required this.onRefresh,
    required this.isRefreshing,
  });

  final Future<void> Function() onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CaptainDesignTokens.s20),
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br24,
        border: Border.all(color: CaptainColors.dividerFor(context)),
        boxShadow: CaptainDesignTokens.softShadow(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(CaptainDesignTokens.s12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CaptainColors.primary.withValues(alpha: 0.10),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  size: 24,
                  color: CaptainColors.primary,
                ),
              ),
              const SizedBox(width: CaptainDesignTokens.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بانتظار رحلتك التالية',
                      style: CaptainTypography.titleSmall(
                        context,
                      ).copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'استرح الآن. فور إسناد رحلة جديدة من العمليات ستظهر هنا '
                      'تلقائياً — لا حاجة لإعادة تسجيل الدخول.',
                      style: CaptainTypography.bodySmall(context).copyWith(
                        color: CaptainColors.textSecondaryFor(context),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s16),
          CaptainLiveSyncChip(isRefreshing: isRefreshing),
          const SizedBox(height: CaptainDesignTokens.s16),
          CaptainButton(
            label: 'تحديث الآن',
            icon: Icons.refresh_rounded,
            isLoading: isRefreshing,
            variant: CaptainButtonVariant.secondary,
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}
