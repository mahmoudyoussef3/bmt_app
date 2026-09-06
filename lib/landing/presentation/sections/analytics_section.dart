import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_charts.dart';
import '../widgets/landing_layout.dart';

/// «التقارير والمؤشرات» — three read-only panels: which lines sell, how full
/// the buses run, and what the months look like beside each other.
class AnalyticsSection extends StatelessWidget {
  const AnalyticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingSectionIntro(
            eyebrow: LandingContent.analyticsEyebrow,
            headline: LandingContent.analyticsHeadline,
            lead: LandingContent.analyticsLead,
            headlineMax: 38,
          ),
          SizedBox(height: landingClamp(context, min: 26, vw: 3.5, max: 42)),
          const LandingAutoGrid(
            minItemWidth: 250,
            spacing: 13,
            stagger: true,
            children: [_TopBookedCard(), _OccupancyCard(), _PeriodCard()],
          ),
        ],
      ),
    );
  }
}

class _TopBookedCard extends StatelessWidget {
  const _TopBookedCard();

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LandingContent.analyticsTopBookedTitle,
            style: LandingType.metric(13.5).copyWith(letterSpacing: 0),
          ),
          const SizedBox(height: 14),
          for (
            var i = 0;
            i < LandingContent.analyticsTopBooked.length;
            i++
          ) ...[
            if (i > 0) const SizedBox(height: 12),
            LandingMeterRow(
              label: LandingContent.analyticsTopBooked[i].name,
              value: LandingContent.analyticsTopBooked[i].trailing,
              fraction: LandingContent.analyticsTopBooked[i].fraction,
            ),
          ],
        ],
      ),
    );
  }
}

class _OccupancyCard extends StatelessWidget {
  const _OccupancyCard();

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // The design centres the gauge with `flex: 1`. A cell in a stretched
        // run is measured with its height unbounded first, and `Expanded`
        // asserts under that, so the free space is distributed by the main
        // axis alignment instead.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            LandingContent.analyticsOccupancyTitle,
            style: LandingType.metric(13.5).copyWith(letterSpacing: 0),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: LandingDonut(
                fraction: LandingContent.analyticsOccupancyFraction,
                value: LandingContent.analyticsOccupancyValue,
                caption: LandingContent.analyticsOccupancyCaption,
              ),
            ),
          ),
          Text(
            LandingContent.analyticsOccupancyFooter,
            textAlign: TextAlign.center,
            style: LandingType.label(12),
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard();

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LandingContent.analyticsPeriodTitle,
            style: LandingType.metric(13.5).copyWith(letterSpacing: 0),
          ),
          const SizedBox(height: 14),
          const LandingPeriodBars(
            heights: LandingContent.analyticsPeriodHeights,
            labels: LandingContent.analyticsPeriodLabels,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < LandingContent.analyticsMini.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(mini: LandingContent.analyticsMini[i]),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.mini});

  final LandingMini mini;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          mini.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LandingType.label(10.5),
        ),
        const SizedBox(height: 2),
        Text(
          mini.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LandingType.metric(16).copyWith(letterSpacing: 0),
        ),
      ],
    );
  }
}
