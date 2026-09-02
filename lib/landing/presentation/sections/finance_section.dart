import 'package:flutter/material.dart';

import '../landing_content.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_atoms.dart';
import '../widgets/landing_charts.dart';
import '../widgets/landing_layout.dart';

/// «الحركة المالية» — four money tiles beside the revenue-against-expenses
/// chart and the payment mix beneath it.
class FinanceSection extends StatelessWidget {
  const FinanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      background: LandingPalette.surface2,
      topBorder: true,
      bottomBorder: true,
      child: LandingSplit(
        breakpoint: 760,
        gap: landingClamp(context, min: 28, vw: 4, max: 52),
        // 330px / 400px bases -> roughly 8:9 once the free space is shared.
        startFlex: 8,
        endFlex: 9,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LandingSectionIntro(
          eyebrow: 'الحركة المالية',
          headline: 'اعرف فلوس مكتبك رايحة فين',
          lead:
              'تابع حركة الإيرادات والمدفوعات والمصروفات من مكان واحد، وخلي '
              'قراراتك مبنية على أرقام واضحة.',
          maxWidth: 500,
          headlineMin: 24,
          headlineVw: 3,
          headlineMax: 38,
        ),
        const SizedBox(height: 24),
        LandingAutoGrid(
          minItemWidth: 150,
          spacing: 11,
          children: [
            for (final kpi in LandingContent.financeKpis)
              _FinanceKpiTile(kpi: kpi),
          ],
        ),
      ],
    );
  }
}

class _FinanceKpiTile extends StatelessWidget {
  const _FinanceKpiTile({required this.kpi});

  final LandingKpi kpi;

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      radius: 11,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            kpi.label,
            style: LandingType.label(11.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  kpi.value,
                  style: LandingType.metric(
                    21,
                    color: kpi.valueColor,
                  ).copyWith(letterSpacing: -0.6),
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 5),
              Text('ج.م', style: LandingType.label(11)),
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
                  'الإيرادات مقابل المصروفات',
                  style: LandingType.cardTitle(13.5),
                ),
              ),
              Text('آخر 8 أسابيع', style: LandingType.label(11)),
            ],
          ),
          const SizedBox(height: 14),
          const LandingDualLineChart(
            revenue: LandingContent.revenuePoints,
            expenses: LandingContent.expensePoints,
            markers: LandingContent.revenueMarkers,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: LandingPalette.borderSoft)),
            ),
            child: const Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _LegendSwatch(color: LandingPalette.brand, label: 'الإيرادات'),
                _LegendSwatch(color: LandingPalette.warn, label: 'المصروفات'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final (index, status) in LandingContent.payStatus.indexed) ...[
            if (index > 0) const SizedBox(height: 10),
            LandingMeterRow(
              label: status.name,
              value: status.value,
              fraction: status.fraction,
              color: status.color,
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color, required this.label});

  final Color color;
  final String label;

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
