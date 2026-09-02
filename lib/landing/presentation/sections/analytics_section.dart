import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_charts.dart';
import '../widgets/landing_layout.dart';

/// «التقارير والمؤشرات» — the three report cards: most-booked routes, the
/// occupancy gauge, and revenue by period.
class AnalyticsSection extends StatelessWidget {
  const AnalyticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LandingSectionIntro(
            eyebrow: 'التقارير والمؤشرات',
            headline: 'مش بس تدير مكتبك... افهم أداءه',
            lead: 'لما تكون الأرقام واضحة، قراراتك بتكون أفضل.',
            headlineMax: 38,
          ),
          SizedBox(height: landingClamp(context, min: 26, vw: 3.5, max: 42)),
          const LandingAutoGrid(
            minItemWidth: 250,
            spacing: 13,
            children: [
              _TopBookedCard(),
              _OccupancyCard(),
              _PeriodRevenueCard(),
            ],
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
          Text('أكثر الخطوط حجزًا', style: LandingType.cardTitle(13.5)),
          const SizedBox(height: 14),
          for (final (index, line) in LandingContent.topBooked.indexed) ...[
            if (index > 0) const SizedBox(height: 12),
            LandingMeterRow(
              label: line.name,
              value: line.value,
              fraction: line.fraction,
              color: line.color,
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
        // The gauge takes the space left between the title and the footnote.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'نسبة إشغال الرحلات',
              style: LandingType.cardTitle(13.5),
            ),
          ),
          const Center(
            child: LandingDonut(
              fraction: 0.87,
              value: '87%',
              caption: 'متوسط الشهر',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '12 خطًا نشطًا · 1,248 رحلة',
              textAlign: TextAlign.center,
              style: LandingType.label(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodRevenueCard extends StatelessWidget {
  const _PeriodRevenueCard();

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('الإيرادات حسب الفترة', style: LandingType.cardTitle(13.5)),
          const SizedBox(height: 14),
          const LandingPeriodBars(
            heights: LandingContent.periodHeights,
            labels: LandingContent.periodLabels,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (index, mini)
                  in LandingContent.analyticsMini.indexed) ...[
                if (index > 0) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mini.label,
                        style: LandingType.label(10.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(mini.value, style: LandingType.cardTitle(16)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
