import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../../../core/entitlements/entitlement_context.dart';
import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_status_chip.dart';

/// الاستخدام والحدود — the only part of this screen that changes daily, and the
/// only part that predicts a refusal.
///
/// The panel it replaces drew one identical progress bar per limit feature,
/// eleven of them, ten reading «بلا حدود» over a track that could never move,
/// two reading «0 / 0» because they were internal catalogue rows the office was
/// never meant to see. The single figure that mattered — how close the office
/// was to a ceiling — was at the same weight as the ten that did not.
///
/// Three groups now, because they are three different statements:
///
///   * **حدود قيد الاستخدام** — a real ceiling. Sorted by pressure, so the meter
///     about to refuse a driver is first and does not have to be found.
///   * **بلا حدود** — no ceiling at all. A chip with the current count; a bar
///     for it is a bar that means nothing.
///   * **غير مشمول** — a ceiling of zero, which is not "nearly full", it is
///     "your plan does not include this".
class OfficeLimitsPanel extends StatelessWidget {
  const OfficeLimitsPanel({
    super.key,
    required this.capped,
    required this.uncapped,
    required this.closed,
    required this.overLimit,
    required this.nearLimit,
    this.isEnforcing = true,
  });

  final List<ResolvedFeature> capped;
  final List<ResolvedFeature> uncapped;
  final List<ResolvedFeature> closed;
  final List<ResolvedFeature> overLimit;
  final List<ResolvedFeature> nearLimit;

  /// The platform's rollout switch. While it is `off`/`shadow` the server allows
  /// everything, so a meter shown as binding would be a lie.
  final bool isEnforcing;

  @override
  Widget build(BuildContext context) {
    if (capped.isEmpty && uncapped.isEmpty && closed.isEmpty) {
      return const DashboardEmptyState(
        icon: DashboardIcons.usage,
        title: 'لا توجد حدود على باقتك',
        message: 'كل عدّاد في هذه الباقة بلا سقف، فلا شيء يُقاس هنا.',
      );
    }

    // Pressure order: over the line first, then closest to it. An office that is
    // over on drivers and at 20% on routes should read "drivers" without
    // scanning, which is the whole job of this list.
    final sorted = [...capped]
      ..sort((a, b) => _pressure(b).compareTo(_pressure(a)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isEnforcing) ...[
          const _Notice(
            tone: AppStatusTone.info,
            icon: DashboardIcons.insight,
            title: 'الحدود غير مُطبَّقة حاليًا',
            message:
                'المنصة لا تفرض حدود الباقات في الوقت الحالي، فالأرقام هنا '
                'للاطّلاع ولا تمنع الإنشاء.',
          ),
          const SizedBox(height: AppSpacing.medium),
        ],
        if (overLimit.isNotEmpty) ...[
          _Notice(
            tone: AppStatusTone.error,
            icon: DashboardIcons.attention,
            title: 'تجاوزت ${_names(overLimit)}',
            message:
                'لن تتمكن من إضافة عناصر جديدة تحت هذا الحد حتى ينزل العدد '
                'تحته أو يُرفع الحد. لم يُحذف ولم يُعطَّل أي عنصر قائم.',
          ),
          const SizedBox(height: AppSpacing.medium),
        ] else if (nearLimit.isNotEmpty) ...[
          _Notice(
            tone: AppStatusTone.warning,
            icon: DashboardIcons.attention,
            title: 'اقتربت من ${_names(nearLimit)}',
            message:
                'تبقّى أقل من ١٥٪ من الحد. رتّب الترقية قبل أن يقف الإنشاء.',
          ),
          const SizedBox(height: AppSpacing.medium),
        ],
        if (sorted.isNotEmpty) _MeterGrid(meters: sorted),
        if (uncapped.isNotEmpty) ...[
          const _GroupLabel(
            icon: DashboardIcons.allClear,
            title: 'بلا حدود في باقتك',
            hint: 'لا سقف لهذه العدّادات — الرقم هو ما لديك الآن.',
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.xSmall,
            children: [for (final f in uncapped) _UncappedChip(meter: f)],
          ),
          const SizedBox(height: AppSpacing.medium),
        ],
        if (closed.isNotEmpty) ...[
          const _GroupLabel(
            icon: DashboardIcons.locked,
            title: 'غير مشمول في باقتك',
            hint: 'حدّها صفر — لا يمكن إنشاء أي عنصر منها على هذه الباقة.',
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.xSmall,
            children: [for (final f in closed) _ClosedChip(meter: f)],
          ),
          const SizedBox(height: AppSpacing.medium),
        ],
        const _MeterRules(),
      ],
    );
  }

  static double _pressure(ResolvedFeature f) {
    final limit = f.limit ?? 0;
    if (limit <= 0) return 0;
    return (f.used ?? 0) / limit;
  }

  /// «حد السائقين» / «حد السائقين و٢ غيرها» — names the metric rather than
  /// making the operator scan a list of bars for the red one.
  static String _names(List<ResolvedFeature> features) {
    if (features.length == 1) return '«${features.first.nameAr}»';
    return '«${features.first.nameAr}» و${features.length - 1} غيرها';
  }
}

/// The meters, two abreast on a wide console.
///
/// One column of full-width tracks across 1280px turns «96 / 100» into a metre
/// of red, and pushes the two panels below it off the first screen. Pressure
/// order runs down the first column then the second, so the meter about to
/// refuse something is still the first one read.
class _MeterGrid extends StatelessWidget {
  const _MeterGrid({required this.meters});

  final List<ResolvedFeature> meters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoUp = constraints.maxWidth >= 900 && meters.length > 1;
        final split = twoUp ? (meters.length / 2).ceil() : meters.length;

        Widget column(Iterable<ResolvedFeature> part) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final meter in part)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                child: _MeterRow(meter: meter),
              ),
          ],
        );

        if (!twoUp) return column(meters);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: column(meters.take(split))),
            const SizedBox(width: AppSpacing.xLarge),
            Expanded(child: column(meters.skip(split))),
          ],
        );
      },
    );
  }
}

/// One meter with a real ceiling: the name, what it counts, where you are, and
/// how much is left.
class _MeterRow extends StatelessWidget {
  const _MeterRow({required this.meter});

  final ResolvedFeature meter;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final limit = meter.limit ?? 0;
    final used = meter.used ?? 0;
    final ratio = limit == 0 ? 0.0 : (used / limit).clamp(0.0, 1.0).toDouble();
    final over = used > limit;

    final tone = over
        ? AppStatusTone.error
        : (ratio >= 0.85 ? AppStatusTone.warning : AppStatusTone.info);
    final status = context.status(tone);

    final unit = meter.unitAr.isEmpty ? '' : ' ${meter.unitAr}';
    final remaining = meter.remaining ?? (limit - used);

    // Name and figure on one line, the bar under both. A full-width track with
    // the number parked at the far end makes the reader sweep the whole console
    // to pair a label with its own value.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Wrap(
                spacing: AppSpacing.small,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    meter.nameAr,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _MeterKindChip(meter: meter),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Text(
              '$used / $limit$unit',
              style: text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: over ? status.accent : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xSmall),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: over ? 1 : ratio,
            minHeight: 8,
            backgroundColor: DashboardColors.well(context),
            valueColor: AlwaysStoppedAnimation(status.accent),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          over
              ? 'تجاوزت الحد بمقدار ${used - limit}$unit'
              : 'متبقٍ $remaining$unit',
          style: text.labelSmall?.copyWith(
            color: over ? status.accent : DashboardColors.mutedInk(context),
            fontWeight: over ? FontWeight.w700 : null,
          ),
        ),
      ],
    );
  }
}

/// stock vs flow, said on the row rather than in a footnote.
///
/// "Why did my number not go down when I deleted that trip" is the first
/// question this data produces, and the answer is a property of the meter.
class _MeterKindChip extends StatelessWidget {
  const _MeterKindChip({required this.meter});

  final ResolvedFeature meter;

  @override
  Widget build(BuildContext context) {
    final flow = meter.isFlowMeter;
    if (meter.meterKind == null) return const SizedBox.shrink();

    return Tooltip(
      message: flow
          ? 'عدّاد شهري يتراكم خلال الشهر — حذف العنصر لا يعيد الحصة.'
          : 'عدّاد لحظي لما هو قائم الآن — حذف العنصر يعيد الحصة.',
      child: DashboardStatusChip(
        label: flow ? 'هذا الشهر' : 'العدد الحالي',
        color: DashboardColors.well(context),
        textColor: DashboardColors.mutedInk(context),
      ),
    );
  }
}

class _UncappedChip extends StatelessWidget {
  const _UncappedChip({required this.meter});

  final ResolvedFeature meter;

  @override
  Widget build(BuildContext context) {
    final used = meter.used;
    final unit = meter.unitAr.isEmpty ? '' : ' ${meter.unitAr}';
    final status = context.status(AppStatusTone.success);

    return DashboardStatusChip(
      label: used == null ? meter.nameAr : '${meter.nameAr} · $used$unit',
      color: status.tint,
      textColor: status.ink,
    );
  }
}

class _ClosedChip extends StatelessWidget {
  const _ClosedChip({required this.meter});

  final ResolvedFeature meter;

  @override
  Widget build(BuildContext context) {
    final status = context.status(AppStatusTone.neutral);
    return DashboardStatusChip(
      label: meter.nameAr,
      color: status.tint,
      textColor: status.ink,
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({
    required this.icon,
    required this.title,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: DashboardColors.mutedInk(context)),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                hint,
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

/// The two rules that govern every figure above, stated once.
class _MeterRules extends StatelessWidget {
  const _MeterRules();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Text(
        'الحد يمنع الإضافة الجديدة فقط: لا يُحذف ولا يُعطَّل أي عنصر قائم عند '
        'تغيير الباقة أو تجاوز الحد. «العدد الحالي» يُحسب لحظيًا من الصفوف '
        'القائمة، فحذف صف يعيد الحصة؛ أما «هذا الشهر» فيتراكم خلال الشهر ولا '
        'يعود بالحذف.',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: DashboardColors.mutedInk(context),
          height: 1.8,
        ),
      ),
    );
  }
}

/// A tinted, titled notice — the over-limit callout and its calmer siblings.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.tone,
    required this.icon,
    required this.title,
    required this.message,
  });

  final AppStatusTone tone;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final status = context.status(tone);
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: status.tint,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: status.accent.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: status.ink),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: status.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: text.bodySmall?.copyWith(
                    color: status.ink,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
