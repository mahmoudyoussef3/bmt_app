import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';

import '../cubit/live_ops_cubit.dart';
import 'live_ops_format.dart';

/// The operations center when there is genuinely nothing happening: no trip on
/// the road and no open report.
///
/// It replaces the two panels rather than letting each draw its own «لا يوجد».
/// Two empty rectangles stacked down the page is the screen at its least useful
/// telling the operator the same thing twice; one statement that names both
/// facts says more in a quarter of the height — the same rule the platform
/// console's signals strip follows, where an empty signal is good news and takes
/// no space.
///
/// It is drawn in the success tone on purpose. A quiet board is not a failure to
/// load, and the neutral grey of an ordinary empty state reads like one on a
/// screen whose whole job is to show movement.
class LiveOpsAllClear extends StatelessWidget {
  /// When the snapshot on screen was read, so the card can say how current this
  /// "nothing" is. A blank live board with no timestamp is indistinguishable
  /// from a frozen one, which is the single most reasonable suspicion an
  /// operator can have about it.
  final DateTime generatedAt;

  final DateTime now;

  const LiveOpsAllClear({
    super.key,
    required this.generatedAt,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final success = context.status(AppStatusTone.success);
    final age = now.difference(generatedAt);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: DashboardColors.panel(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.border(context)),
        boxShadow: DashboardColors.panelShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: success.tint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DashboardColors.statusLine(
                      context,
                      AppStatusTone.success,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.verified_rounded,
                  size: 21,
                  color: success.ink,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الوضع هادئ',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'لا شيء على الطريق يتطلب تدخلاً من فريق العمليات الآن.',
                      style: text.bodySmall?.copyWith(
                        color: DashboardColors.mutedInk(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          LayoutBuilder(
            builder: (context, constraints) {
              // Side by side while both facts still get a readable measure;
              // stacked below that, which is also where the console runs in
              // drawer mode.
              final twoCols = constraints.maxWidth >= 560;
              final width = twoCols
                  ? (constraints.maxWidth - AppSpacing.medium) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: AppSpacing.medium,
                runSpacing: AppSpacing.small,
                children: [
                  SizedBox(
                    width: width,
                    child: const _QuietFact(
                      icon: DashboardIcons.trips,
                      title: 'لا رحلات على الطريق',
                      message:
                          'ستظهر هنا فور أن يبدأ الكباتن تنفيذها، مع تتبّع مباشر لكل مركبة.',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: const _QuietFact(
                      icon: DashboardIcons.incident,
                      title: 'لا بلاغات مفتوحة',
                      message: 'كل البلاغات الواردة من الكباتن تمت معالجتها.',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.medium),
          Divider(height: 1, color: DashboardColors.divider(context)),
          const SizedBox(height: AppSpacing.small),
          _FreshnessLine(age: age),
        ],
      ),
    );
  }
}

/// One of the two things that are quiet, stated with what would fill it.
///
/// Flat rows, not tinted tiles: a card inside a card is the one arrangement the
/// dashboard's card language always gets wrong, and there is nothing here to
/// separate from its surroundings.
class _QuietFact extends StatelessWidget {
  const _QuietFact({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final success = context.status(AppStatusTone.success);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: DashboardColors.mutedInk(context)),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: text.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.check_rounded, size: 15, color: success.ink),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: text.labelSmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Says the board is live and how current it is.
///
/// The cadence is read off [LiveOpsCubit.pollInterval] rather than typed in, so
/// the sentence cannot drift away from the timer it describes.
class _FreshnessLine extends StatelessWidget {
  const _FreshnessLine({required this.age});

  final Duration age;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final seconds = LiveOpsCubit.pollInterval.inSeconds;
    final faint = DashboardColors.faintInk(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.autorenew_rounded, size: 15, color: faint),
        const SizedBox(width: AppSpacing.xSmall),
        Expanded(
          child: Text(
            'تُحدَّث الشاشة تلقائياً كل $seconds ثانية · آخر قراءة ${liveOpsAgo(age)}',
            style: text.labelSmall?.copyWith(color: faint),
          ),
        ),
      ],
    );
  }
}
