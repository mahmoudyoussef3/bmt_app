import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_charts.dart';
import '../widgets/landing_layout.dart';

/// «الحركة المالية» — the four numbers an owner checks first, next to the
/// eight-week shape behind them.
class FinanceSection extends StatelessWidget {
  const FinanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      background: LandingPalette.surface2,
      topBorder: true,
      bottomBorder: true,
      child: LandingSplit(
        breakpoint: 780,
        gap: landingClamp(context, min: 28, vw: 4, max: 52),
        startFlex: 33,
        endFlex: 40,
        start: const _FinanceCopy(),
        end: const _FinanceChartCard(),
      ),
    );
  }
}

class _FinanceCopy extends StatelessWidget {
  const _FinanceCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const LandingSectionIntro(
          eyebrow: LandingContent.financeEyebrow,
          headline: LandingContent.financeHeadline,
          lead: LandingContent.financeLead,
          maxWidth: 500,
          headlineMin: 24,
          headlineVw: 3,
          headlineMax: 38,
        ),
        const SizedBox(height: 24),
        LandingAutoGrid(
          minItemWidth: 150,
          spacing: 11,
          stagger: true,
          children: [
            for (final kpi in LandingContent.financeKpis)
              _FinanceKpiCard(kpi: kpi),
          ],
        ),
      ],
    );
  }
}

class _FinanceKpiCard extends StatelessWidget {
  const _FinanceKpiCard({required this.kpi});

  final LandingMoney kpi;

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      radius: 11,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kpi.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LandingType.label(11.5),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  kpi.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: LandingType.metric(
                    21,
                    color: kpi.color,
                  ).copyWith(letterSpacing: -0.6),
                ),
              ),
              const SizedBox(width: 5),
              Text(LandingContent.currencySuffix, style: LandingType.label(11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceChartCard extends StatelessWidget {
  const _FinanceChartCard();

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.all(18),
      shadow: const [
        BoxShadow(
          color: Color(0x4D0B1B34),
          offset: Offset(0, 26),
          blurRadius: 54,
          spreadRadius: -34,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  LandingContent.financeChartTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LandingType.metric(13.5).copyWith(letterSpacing: 0),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                LandingContent.financeChartNote,
                style: LandingType.label(11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const LandingDualLineChart(
            revenue: LandingContent.financeRevenue,
            expenses: LandingContent.financeExpenses,
            markers: LandingContent.financeMarkers,
          ),
          const SizedBox(height: 10),
          const Divider(
            height: 13,
            thickness: 1,
            color: LandingPalette.borderSoft,
          ),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: const [
              _LegendItem(
                label: LandingContent.financeRevenueLabel,
                color: LandingPalette.brand,
              ),
              _LegendItem(
                label: LandingContent.financeExpenseLabel,
                color: LandingPalette.warn,
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < LandingContent.financePayStatus.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            LandingMeterRow(
              label: LandingContent.financePayStatus[i].name,
              value: LandingContent.financePayStatus[i].trailing,
              fraction: LandingContent.financePayStatus[i].fraction,
              color: LandingContent.financePayStatus[i].color,
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: LandingType.label(11.5)),
      ],
    );
  }
}
