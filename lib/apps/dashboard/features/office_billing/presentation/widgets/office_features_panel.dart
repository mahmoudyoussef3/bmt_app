import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../../../core/entitlements/entitlement_context.dart';
import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_status_chip.dart';
import '../../../platform_licensing/presentation/widgets/licensing_widgets.dart';

/// ما تشمله باقتك — what is on, and for everything that is off, **why**.
///
/// The panel this replaces drew every feature as a chip in one of three colours
/// whose meaning lived in a tooltip, so "غير متاحة في باقتك الحالية" was the
/// answer given for four different situations: a plan that does not include it,
/// a platform kill switch, a licence hold, and a prerequisite that is off. Those
/// are four different remedies — buy an upgrade, wait for the platform, pay the
/// invoice, turn something else on — and the resolver has always said which one
/// it is in `source` and `blockedBy`.
///
/// So: available features stay chips (they need no explanation), and everything
/// off becomes a row that names its own reason.
class OfficeFeaturesPanel extends StatelessWidget {
  const OfficeFeaturesPanel({
    super.key,
    required this.groups,
    required this.nameOfFeature,
    this.onContact,
  });

  /// Category label → the features resolved for it, already filtered to the
  /// public, enforced, non-limit ones the office could actually hold.
  final Map<String, List<ResolvedFeature>> groups;

  /// Resolves a feature key to its Arabic name. `blockedBy` carries a key, and
  /// telling an office its feature "requires live_tracking" is telling it
  /// nothing — the prerequisite has a name in the same document.
  final String Function(String key) nameOfFeature;

  final VoidCallback? onContact;

  static const categories = <String, String>{
    'operations': 'التشغيل',
    'fleet': 'الأسطول',
    'sales': 'المبيعات والعملاء',
    'finance': 'المالية',
    'insight': 'التقارير والتحليل',
    'engagement': 'التواصل والدعم',
    'platform': 'المنصة والتوسع',
  };

  @override
  Widget build(BuildContext context) {
    final available = <String, List<ResolvedFeature>>{};
    final locked = <ResolvedFeature>[];
    final lockedCategory = <String, String>{};

    for (final entry in groups.entries) {
      final on = entry.value.where((f) => f.isOn).toList(growable: false);
      if (on.isNotEmpty) available[entry.key] = on;
      for (final feature in entry.value.where((f) => !f.isOn)) {
        locked.add(feature);
        lockedCategory[feature.key] = entry.key;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (available.isEmpty)
          Text(
            'لا توجد ميزات مفعّلة على باقتك الحالية.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          )
        else
          _AvailableGroups(groups: available),
        if (locked.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.small),
          _LockedBlock(
            features: locked,
            category: lockedCategory,
            nameOfFeature: nameOfFeature,
          ),
        ],
        const SizedBox(height: AppSpacing.medium),
        _UpgradeNote(onContact: onContact),
      ],
    );
  }
}

/// Seven categories of short chips down one column leaves half a wide console
/// empty. Two columns above 900px, one below — the same breakpoint the office
/// profile's two status panels use.
class _AvailableGroups extends StatelessWidget {
  const _AvailableGroups({required this.groups});

  final Map<String, List<ResolvedFeature>> groups;

  @override
  Widget build(BuildContext context) {
    final entries = groups.entries.toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 2 : 1;
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                  child: _AvailableGroup(
                    title: entry.key,
                    features: entry.value,
                  ),
                ),
            ],
          );
        }

        // Down the first column, then the second: reading order for a list of
        // labelled groups is vertical, and dealing them across the row would
        // put «الأسطول» beside «التشغيل» and «المالية» under «التشغيل».
        final split = (entries.length / 2).ceil();
        Widget column(Iterable<MapEntry<String, List<ResolvedFeature>>> part) =>
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in part)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: _AvailableGroup(
                      title: entry.key,
                      features: entry.value,
                    ),
                  ),
              ],
            );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: column(entries.take(split))),
            const SizedBox(width: AppSpacing.xLarge),
            Expanded(child: column(entries.skip(split))),
          ],
        );
      },
    );
  }
}

class _AvailableGroup extends StatelessWidget {
  const _AvailableGroup({required this.title, required this.features});

  final String title;
  final List<ResolvedFeature> features;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.xSmall),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.xSmall,
          children: [for (final f in features) _AvailableChip(feature: f)],
        ),
      ],
    );
  }
}

class _AvailableChip extends StatelessWidget {
  const _AvailableChip({required this.feature});

  final ResolvedFeature feature;

  @override
  Widget build(BuildContext context) {
    // An override is the office holding something its plan does not give it.
    // Worth saying: it is the answer to "we were told we'd get this", and when
    // it expires the feature goes away again.
    final granted = feature.source == 'override';
    final status = context.status(
      granted ? AppStatusTone.special : AppStatusTone.success,
    );

    final expiry = feature.expiresAt;
    final tooltip = StringBuffer(
      granted ? 'استثناء ممنوح لمكتبك خارج الباقة' : 'متاحة في باقتك',
    );
    if (expiry != null) tooltip.write(' — حتى ${licensingDate(expiry)}');

    return Tooltip(
      message: tooltip.toString(),
      child: DashboardStatusChip(
        label: feature.valueType == 'enum'
            ? '${feature.nameAr}: ${feature.value}'
            : feature.nameAr,
        color: status.tint,
        textColor: status.ink,
      ),
    );
  }
}

/// Everything the office does not have, each with the sentence that explains it.
class _LockedBlock extends StatelessWidget {
  const _LockedBlock({
    required this.features,
    required this.category,
    required this.nameOfFeature,
  });

  final List<ResolvedFeature> features;
  final Map<String, String> category;
  final String Function(String key) nameOfFeature;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'غير مشمول حاليًا',
          style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          'ما لا تشمله باقتك اليوم، ولماذا.',
          style: text.labelSmall?.copyWith(
            color: DashboardColors.mutedInk(context),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Container(
          decoration: BoxDecoration(
            color: DashboardColors.well(context),
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(color: DashboardColors.border(context)),
          ),
          child: Column(
            children: [
              for (final (index, feature) in features.indexed) ...[
                if (index > 0)
                  Divider(height: 1, color: DashboardColors.divider(context)),
                _LockedRow(
                  feature: feature,
                  category: category[feature.key] ?? '',
                  nameOfFeature: nameOfFeature,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LockedRow extends StatelessWidget {
  const _LockedRow({
    required this.feature,
    required this.category,
    required this.nameOfFeature,
  });

  final ResolvedFeature feature;
  final String category;
  final String Function(String key) nameOfFeature;

  /// Four causes, four remedies. The resolver reports `source` *and*
  /// `blockedBy` because both can be true at once — an override that grants a
  /// feature whose prerequisite is off is honoured at its rung and defeated at
  /// the gate — and the dependency is the one the office can act on, so it wins
  /// the sentence.
  (String, AppStatusTone) get _reason {
    final blocker = feature.blockedBy;
    if (blocker != null && blocker.isNotEmpty) {
      return (
        'تتطلب تفعيل «${nameOfFeature(blocker)}» أولًا',
        AppStatusTone.warning,
      );
    }
    return switch (feature.source) {
      'kill_switch' => (
        'موقوفة على مستوى المنصة مؤقتًا — لا علاقة لها بباقتك',
        AppStatusTone.error,
      ),
      'license_hold' => (
        'معلّقة بسبب حالة اشتراكك — تعود بمجرد عودة الترخيص',
        AppStatusTone.error,
      ),
      'override' => (
        'مستثناة لمكتبك بقرار من إدارة المنصة',
        AppStatusTone.special,
      ),
      _ => ('غير مشمولة في باقتك الحالية', AppStatusTone.neutral),
    };
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (sentence, tone) = _reason;
    final status = context.status(tone);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            DashboardIcons.locked,
            size: 16,
            color: DashboardColors.mutedInk(context),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.nameAr,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  sentence,
                  style: text.bodySmall?.copyWith(color: status.accent),
                ),
              ],
            ),
          ),
          if (category.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.small),
            Text(
              category,
              style: text.labelSmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpgradeNote extends StatelessWidget {
  const _UpgradeNote({this.onContact});

  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: DashboardColors.border(context)),
      ),
      child: Wrap(
        spacing: AppSpacing.medium,
        runSpacing: AppSpacing.small,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(DashboardIcons.locked, size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.small),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'لترقية الباقة أو رفع أي حد، تواصل مع إدارة المنصة. '
                  'تغيير الباقة لا يتم ذاتيًا في هذا الإصدار.',
                  style: text.bodySmall,
                ),
              ),
            ],
          ),
          if (onContact != null)
            OutlinedButton(
              onPressed: onContact,
              child: const Text('جهّز طلب ترقية'),
            ),
        ],
      ),
    );
  }
}
