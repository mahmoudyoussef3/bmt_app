import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_collapsible_section.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_module_header.dart';
import '../../../../core/widgets/dashboard_panel.dart';
import '../../../../core/widgets/master_detail_layout.dart';
import '../../domain/entities/licensing_catalog.dart';
import '../../domain/entities/office_license.dart';
import '../cubit/platform_licensing_cubit.dart';
import '../cubit/platform_licensing_state.dart';
import '../widgets/assign_plan_dialog.dart';
import '../widgets/licensing_layout.dart';
import '../widgets/licensing_scaffold.dart';
import '../widgets/licensing_widgets.dart';

/// التراخيص — every office's licence, and the one screen that answers
/// "why does this office have this?".
///
/// The answer lives in the `source` of each resolved feature: which rung of the
/// ladder produced the value. That single field is the difference between a
/// two-minute support conversation and a twenty-minute one.
///
/// **What changed, and why.** The screen used to open with six health cards —
/// all six, always, most of them saying "لا يوجد" — before the office list was
/// even reachable. Signals now appear only when they have something to say, as
/// a row of counts that expands into its offices on tap. The office list gained
/// the search field it never had. And the licence actions came out of a `⋯`
/// menu buried in a panel header and onto a visible bar: assigning a plan is
/// the most common thing done on this screen and it was the hardest to find.
class PlatformLicensesScreen extends StatefulWidget {
  const PlatformLicensesScreen({super.key});

  @override
  State<PlatformLicensesScreen> createState() => _PlatformLicensesScreenState();
}

class _PlatformLicensesScreenState extends State<PlatformLicensesScreen> {
  String _query = '';

  /// The alert whose office list is open, if any. One at a time: two open lists
  /// push the office list off the screen, which is the problem the strip had.
  String? _openAlert;

  @override
  Widget build(BuildContext context) {
    return LicensingScreenFrame(
      // The page scrolls as one — the same shape the offices and wallet screens
      // use. A viewport-height column cannot hold a signal strip, a full office
      // list and a licence panel at once, and squeezing them into it is what
      // clipped all three.
      builder: (context, state) => ListView(
        padding: EdgeInsets.zero,
        children: [
          _LicensesHeader(state: state),
          const SizedBox(height: AppSpacing.medium),
          _AlertStrip(
            state: state,
            openKey: _openAlert,
            onToggle: (key) =>
                setState(() => _openAlert = _openAlert == key ? null : key),
          ),
          const SizedBox(height: AppSpacing.medium),
          MasterDetailLayout(
            masterFlex: 2,
            detailFlex: 3,
            placeholderTitle: 'اختر مكتبًا لعرض ترخيصه',
            placeholderSubtitle:
                'كل قيمة تظهر ومعها مصدرها: باقة، استثناء، أو حالة ترخيص.',
            master: _OfficeList(
              state: state,
              query: _query,
              onQuery: (q) => setState(() => _query = q),
            ),
            detail: state.selectedOffice == null
                ? null
                : _OfficeLicensePanel(state: state),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════════════════

class _LicensesHeader extends StatelessWidget {
  const _LicensesHeader({required this.state});

  final PlatformLicensingLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final scheme = Theme.of(context).colorScheme;
    final licenses = state.licenses;
    final active = licenses.where((l) => l.status == 'active').length;
    final trialing = licenses.where((l) => l.status == 'trialing').length;

    return DashboardModuleHeader(
      icon: DashboardIcons.licenses,
      title: 'التراخيص',
      subtitle: 'الحالة التجارية لكل مكتب، وما تسمح به فعليًا.',
      actions: [
        OutlinedButton.icon(
          onPressed: cubit.runLifecycle,
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('تشغيل دورة الحياة'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LicensingStatStrip(
            stats: [
              LicensingStat(
                icon: DashboardIcons.platformOffices,
                value: '${licenses.length}',
                label: 'مكتب مرخَّص',
              ),
              LicensingStat(
                icon: DashboardIcons.allClear,
                value: '$active',
                label: 'ترخيص نشط',
                color: scheme.secondary,
              ),
              LicensingStat(
                icon: DashboardIcons.time,
                value: '$trialing',
                label: 'فترة تجريبية',
              ),
              LicensingStat(
                icon: DashboardIcons.usage,
                value: '${state.overLimitOffices}',
                label: 'تجاوز حدًّا',
                color: state.overLimitOffices > 0 ? scheme.error : null,
              ),
              LicensingStat(
                icon: DashboardIcons.locked,
                value: '${state.delistedOffices}',
                label: 'محجوب عن السوق',
                color: state.delistedOffices > 0 ? scheme.error : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          _EnforcementModeBar(state: state),
        ],
      ),
    );
  }
}

class _EnforcementModeBar extends StatelessWidget {
  const _EnforcementModeBar({required this.state});

  final PlatformLicensingLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final scheme = Theme.of(context).colorScheme;
    final mode = state.settings.enforcementMode;
    final color = switch (mode) {
      'enforcing' => scheme.secondary,
      'shadow' => scheme.tertiary,
      _ => scheme.outline,
    };

    final segmented = SegmentedButton<String>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
      segments: const [
        ButtonSegment(value: 'off', label: Text('معطّل')),
        ButtonSegment(value: 'shadow', label: Text('ظل')),
        ButtonSegment(value: 'enforcing', label: Text('مفعّل')),
      ],
      selected: {mode},
      onSelectionChanged: (selection) =>
          cubit.setEnforcementMode(selection.first),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final label = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'وضع التطبيق: ${state.settings.modeLabelAr}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                // The kill switch, described where it lives.
                'الإرجاع إلى «معطّل» يعيد سلوك المنصة كما كان فورًا وبلا نشر '
                'إصدار جديد.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 640) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                label,
                const SizedBox(height: AppSpacing.small),
                segmented,
              ],
            );
          }
          return Row(
            children: [
              Icon(DashboardIcons.settings, color: color, size: 20),
              const SizedBox(width: AppSpacing.small),
              Expanded(child: label),
              segmented,
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Alerts
// ═══════════════════════════════════════════════════════════════════════════

/// One thing worth chasing today.
typedef _Alert = ({
  String key,
  IconData icon,
  String title,
  List<Map<String, dynamic>> rows,
  Color Function(ColorScheme) tone,
  String Function(Map<String, dynamic>) describe,
  bool selectable,
});

/// The signals that have something to say, and nothing else.
///
/// Six cards that are mostly empty is not a health strip, it is a wall. An
/// empty signal is good news and takes no space; a signal with rows becomes a
/// count you can press to see exactly which offices it means.
class _AlertStrip extends StatelessWidget {
  const _AlertStrip({
    required this.state,
    required this.openKey,
    required this.onToggle,
  });

  final PlatformLicensingLoaded state;
  final String? openKey;
  final ValueChanged<String> onToggle;

  List<_Alert> _alerts(ColorScheme scheme) {
    final health = state.health;
    return [
      (
        key: 'past_due',
        icon: DashboardIcons.attention,
        title: 'متأخرة أو موقوفة',
        rows: health.pastDue,
        tone: (s) => s.error,
        describe: (r) => '${r['office_name']} — ${r['status']}',
        selectable: true,
      ),
      (
        key: 'over_limit',
        icon: DashboardIcons.usage,
        title: 'تجاوزت حدًّا',
        rows: health.overLimit,
        tone: (s) => s.error,
        describe: (r) =>
            '${r['office_name']} — ${r['name_ar']}: ${r['used']} / ${r['limit']}',
        selectable: true,
      ),
      (
        key: 'no_license',
        icon: DashboardIcons.platformOffices,
        title: 'مكاتب بلا ترخيص',
        rows: health.officesWithoutLicense,
        tone: (s) => s.error,
        describe: (r) => '${r['office_name']}',
        selectable: true,
      ),
      (
        key: 'trials',
        icon: DashboardIcons.time,
        title: 'تجارب تنتهي قريبًا',
        rows: health.trialsEnding,
        tone: (s) => s.tertiary,
        describe: (r) =>
            '${r['office_name']} — ${licensingDate(DateTime.tryParse('${r['trial_ends_at']}'))}',
        selectable: true,
      ),
      (
        key: 'overrides',
        icon: DashboardIcons.locked,
        title: 'استثناءات تنتهي قريبًا',
        rows: health.overridesExpiring,
        tone: (s) => s.tertiary,
        describe: (r) => '${r['office_name']} — ${r['feature_key']}',
        selectable: true,
      ),
      (
        key: 'sold',
        icon: DashboardIcons.featureCatalog,
        title: 'مُباعة بلا كود',
        rows: health.soldButDeclared,
        tone: (s) => s.tertiary,
        describe: (r) => '${r['plan_key']} — ${r['name_ar']}',
        // A plan-level defect, not an office-level one: there is no office to
        // open from this row.
        selectable: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<PlatformLicensingCubit>();
    final alerts = _alerts(scheme).where((a) => a.rows.isNotEmpty).toList();

    if (alerts.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: LicensingNotice(
          icon: DashboardIcons.allClear,
          color: scheme.secondary,
          message:
              'لا شيء يحتاج انتباهك الآن: لا تجارب على وشك الانتهاء، ولا '
              'تأخّر سداد، ولا مكتب متجاوز حدًّا.',
        ),
      );
    }

    final open = alerts.where((a) => a.key == openKey).firstOrNull;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(DashboardIcons.attention, size: 20, color: scheme.tertiary),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  'يحتاج انتباهك',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'اضغط أي بطاقة لعرض مكاتبها',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: DashboardColors.mutedInk(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          LicensingCardGrid(
            minCardWidth: 220,
            spacing: AppSpacing.small,
            children: [
              for (final alert in alerts)
                _AlertTile(
                  alert: alert,
                  color: alert.tone(scheme),
                  open: alert.key == openKey,
                  onTap: () => onToggle(alert.key),
                ),
            ],
          ),
          if (open != null) ...[
            const SizedBox(height: AppSpacing.medium),
            _AlertRows(
              alert: open,
              color: open.tone(scheme),
              onSelect: open.selectable ? cubit.selectOffice : null,
            ),
          ],
          const SizedBox(height: AppSpacing.small),
          Text(
            // The line that stops an over-limit being read as an accusation.
            'تجاوز الحد حالة حقيقية وليست خطأ: الحدود تمنع الإنشاء الجديد ولا '
            'تمسّ ما هو قائم، فالمكتب الذي خُفِّضت باقته يحتفظ بكل صفوفه.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.alert,
    required this.color,
    required this.open,
    required this.onTap,
  });

  final _Alert alert;
  final Color color;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppTokens.radiusSmall);

    return Material(
      color: color.withAlpha(open ? 34 : 16),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: color.withAlpha(open ? 160 : 70),
              width: open ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(alert.icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${alert.rows.length}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    Text(
                      alert.title,
                      maxLines: 2,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 20,
                color: DashboardColors.mutedInk(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertRows extends StatelessWidget {
  const _AlertRows({
    required this.alert,
    required this.color,
    required this.onSelect,
  });

  final _Alert alert;
  final Color color;
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: DashboardColors.well(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${alert.title} — ${alert.rows.length}',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          // Every row, never a "and N more": the card listing eleven offices is
          // precisely the one the operator opened this screen for.
          for (final row in alert.rows)
            InkWell(
              onTap: onSelect == null || row['office_id'] == null
                  ? null
                  : () => onSelect!(row['office_id'] as String),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.describe(row),
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onSelect != null && row['office_id'] != null)
                      Icon(
                        DashboardIcons.openModule,
                        size: 16,
                        color: DashboardColors.mutedInk(context),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Master — the office list
// ═══════════════════════════════════════════════════════════════════════════

class _OfficeList extends StatelessWidget {
  const _OfficeList({
    required this.state,
    required this.query,
    required this.onQuery,
  });

  final PlatformLicensingLoaded state;
  final String query;
  final ValueChanged<String> onQuery;

  static const _statuses = <String?, String>{
    null: 'الكل',
    'active': 'نشطة',
    'trialing': 'تجريبية',
    'past_due': 'متأخرة',
    'grace': 'مهلة',
    'suspended': 'موقوفة',
    'expired': 'منتهية',
  };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final q = query.trim().toLowerCase();
    final rows = state.visibleLicenses.where((row) {
      if (q.isEmpty) return true;
      return row.officeName.toLowerCase().contains(q) ||
          row.planNameAr.contains(q) ||
          row.officeSlug.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.small),
      child: DashboardPanel(
        sectionId: DashboardSectionIds.platformLicenseOffices,
        icon: DashboardIcons.licenses,
        title: 'المكاتب',
        subtitle: rows.length == state.licenses.length
            ? '${state.licenses.length} مكتب'
            : '${rows.length} من ${state.licenses.length} مكتب',
        collapsedSummary: DashboardSectionSummary(
          items: [
            '${rows.length} مكتب',
            if (state.licenseStatusFilter != null)
              _statuses[state.licenseStatusFilter] ??
                  state.licenseStatusFilter!,
            if (q.isNotEmpty) 'بحث: $q',
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The list had no search at all: finding an office meant scrolling
            // past every other one, or knowing its status by heart.
            DebouncedSearchField(
              initialValue: query,
              hintText: 'ابحث باسم المكتب أو باقته',
              onChanged: onQuery,
            ),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.xSmall,
              runSpacing: AppSpacing.xSmall,
              children: [
                for (final entry in _statuses.entries)
                  if (entry.key == null ||
                      state.licenses.any((l) => l.status == entry.key))
                    FilterChip(
                      label: Text(
                        entry.key == null
                            ? entry.value
                            : '${entry.value} '
                                  '(${state.licenses.where((l) => l.status == entry.key).length})',
                      ),
                      selected: state.licenseStatusFilter == entry.key,
                      onSelected: (_) => cubit.filterLicenses(entry.key),
                    ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            if (rows.isEmpty)
              DashboardEmptyState(
                icon: DashboardIcons.licenses,
                title: 'لا يوجد مكتب مطابق',
                message: 'جرّب اسمًا آخر أو أزل تصفية الحالة.',
                action: TextButton(
                  onPressed: () {
                    onQuery('');
                    cubit.filterLicenses(null);
                  },
                  child: const Text('عرض كل المكاتب'),
                ),
              )
            else
              for (final row in rows)
                _OfficeTile(
                  row: row,
                  selected: state.selectedOffice?.officeId == row.officeId,
                  onTap: () => cubit.selectOffice(row.officeId),
                ),
          ],
        ),
      ),
    );
  }
}

class _OfficeTile extends StatelessWidget {
  const _OfficeTile({
    required this.row,
    required this.selected,
    required this.onTap,
  });

  final OfficeLicenseRow row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppTokens.radiusSmall);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withAlpha(20)
                  : DashboardColors.well(context),
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? scheme.primary.withAlpha(140)
                    : DashboardColors.border(context),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.officeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        row.planNameAr.isEmpty ? 'بلا باقة' : row.planNameAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: DashboardColors.mutedInk(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (row.overLimitCount > 0) ...[
                  StatusChip(
                    label: 'تجاوز ${row.overLimitCount}',
                    color: scheme.error.withAlpha(24),
                    textColor: scheme.error,
                  ),
                  const SizedBox(width: AppSpacing.xSmall),
                ],
                if (row.isDelisted) ...[
                  Tooltip(
                    message: 'محجوب عن سوق العملاء',
                    child: Icon(
                      DashboardIcons.locked,
                      size: 16,
                      color: scheme.error,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xSmall),
                ],
                LicenseStatusChip(status: row.status, label: row.statusLabelAr),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Detail — one office
// ═══════════════════════════════════════════════════════════════════════════

class _OfficeLicensePanel extends StatelessWidget {
  const _OfficeLicensePanel({required this.state});

  final PlatformLicensingLoaded state;

  @override
  Widget build(BuildContext context) {
    final detail = state.selectedOffice!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OfficeHeader(state: state, detail: detail),
        const SizedBox(height: AppSpacing.medium),
        _LimitsSection(detail: detail),
        const SizedBox(height: AppSpacing.medium),
        _OverridesSection(state: state, detail: detail),
        const SizedBox(height: AppSpacing.medium),
        _EffectiveFeaturesSection(detail: detail),
        const SizedBox(height: AppSpacing.medium),
        _InvoicesSection(detail: detail),
        const SizedBox(height: AppSpacing.medium),
        _ActivitySection(detail: detail),
      ],
    );
  }
}

/// The office's licence, its facts, and every action that can be taken on it.
///
/// The actions used to live behind a `⋯` in a panel header — «تعيين باقة», the
/// single most common operation on this screen, took two clicks and prior
/// knowledge of where it hid.
class _OfficeHeader extends StatelessWidget {
  const _OfficeHeader({required this.state, required this.detail});

  final PlatformLicensingLoaded state;
  final OfficeLicenseDetail detail;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final license = detail.license;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                ),
                child: Icon(
                  DashboardIcons.platformOfficesActive,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.officeName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: AppSpacing.xSmall,
                      runSpacing: AppSpacing.xSmall,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        LicenseStatusChip(
                          status: license.status,
                          label: license.statusLabelAr,
                        ),
                        Text(
                          license.planNameAr.isEmpty
                              ? 'بلا باقة'
                              : license.planNameAr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (detail.licensingHold != 'none')
                          StatusChip(
                            label: detail.licensingHold == 'delisted'
                                ? 'محجوب عن العملاء'
                                : 'قراءة فقط',
                            color: scheme.error.withAlpha(24),
                            textColor: scheme.error,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'إغلاق',
                icon: const Icon(Icons.close_rounded),
                onPressed: cubit.clearOfficeSelection,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              FilledButton.icon(
                onPressed: () => _assign(context, cubit),
                icon: const Icon(DashboardIcons.plans, size: 18),
                label: Text(
                  license.planNameAr.isEmpty ? 'تعيين باقة' : 'تغيير الباقة',
                ),
              ),
              if (license.status == 'trialing')
                OutlinedButton.icon(
                  onPressed: () => _extend(context, cubit),
                  icon: const Icon(DashboardIcons.time, size: 18),
                  label: const Text('تمديد التجربة'),
                ),
              if (license.isHeld)
                OutlinedButton.icon(
                  onPressed: () => _restore(context, cubit),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('استئناف'),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _suspend(context, cubit),
                  icon: const Icon(Icons.pause_rounded, size: 18),
                  label: const Text('إيقاف مؤقت'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => cubit.issueInvoice(detail.officeId),
                icon: const Icon(DashboardIcons.billing, size: 18),
                label: const Text('إصدار فاتورة'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Divider(height: 1, color: DashboardColors.divider(context)),
          const SizedBox(height: AppSpacing.small),
          LicensingFieldGrid(
            fields: [
              (
                label: 'الدورة',
                value: switch (license.billingCycle) {
                  'monthly' => 'شهرية',
                  'yearly' => 'سنوية',
                  'custom' => 'عقد مخصص',
                  'free' => 'مجانية',
                  _ => '—',
                },
              ),
              (
                label: 'السعر',
                value: licensingMoney(license.price, license.currency),
              ),
              if (license.trialEndsAt != null)
                (
                  label: 'تنتهي التجربة',
                  value: licensingDate(license.trialEndsAt),
                ),
              (label: 'نهاية المدة', value: licensingDate(license.periodEnd)),
              (label: 'تجديد تلقائي', value: license.autoRenew ? 'نعم' : 'لا'),
              if (license.suspendedReason != null)
                (label: 'سبب الإيقاف', value: license.suspendedReason!),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _assign(
    BuildContext context,
    PlatformLicensingCubit cubit,
  ) async {
    final choice = await showAssignPlanDialog(
      context,
      plans: state.plans.where((p) => !p.isArchived).toList(),
      officeName: detail.officeName,
      currentPlanKey: detail.license.planKey,
      currentCycle: detail.license.billingCycle,
    );
    if (choice == null) return;
    await cubit.assignPlan(detail.officeId, choice.planId, cycle: choice.cycle);
  }

  Future<void> _suspend(
    BuildContext context,
    PlatformLicensingCubit cubit,
  ) async {
    final reason = await promptForReason(
      context,
      title: 'إيقاف ترخيص «${detail.officeName}» مؤقتًا',
      // Said at the moment of the decision, because this is the action most
      // often assumed to be a blackout.
      description:
          'المكتب سيتحوّل إلى وضع القراءة فقط: لا إنشاء رحلات أو سائقين أو '
          'خطوط، ويختفي من سوق العملاء. التذاكر المُباعة والرحلات الجارية '
          'ودخول الكباتن تكمل كالمعتاد.',
      confirmLabel: 'إيقاف',
      suggestions: const [
        'تأخّر السداد عن الموعد المتفق عليه',
        'طلب المكتب إيقاف الخدمة مؤقتًا',
        'مخالفة شروط الاستخدام قيد المراجعة',
      ],
    );
    if (reason == null || !context.mounted) return;
    await cubit.setLicenseStatus(detail.officeId, 'suspended', reason);
  }

  Future<void> _restore(
    BuildContext context,
    PlatformLicensingCubit cubit,
  ) async {
    final reason = await promptForReason(
      context,
      title: 'استئناف ترخيص «${detail.officeName}»',
      confirmLabel: 'استئناف',
      suggestions: const [
        'تم سداد المستحقات بالكامل',
        'انتهت المراجعة ولا مخالفة',
        'اتفاق تجاري جديد مع المكتب',
      ],
    );
    if (reason == null || !context.mounted) return;
    await cubit.setLicenseStatus(detail.officeId, 'active', reason);
  }

  Future<void> _extend(
    BuildContext context,
    PlatformLicensingCubit cubit,
  ) async {
    final reason = await promptForReason(
      context,
      title: 'تمديد الفترة التجريبية ١٤ يومًا',
      confirmLabel: 'تمديد',
      suggestions: const [
        'المكتب ما زال يجهّز بياناته التشغيلية',
        'تمديد متفق عليه مع فريق المبيعات',
      ],
    );
    if (reason == null || !context.mounted) return;
    await cubit.extendTrial(detail.officeId, 14, reason);
  }
}

class _LimitsSection extends StatelessWidget {
  const _LimitsSection({required this.detail});

  final OfficeLicenseDetail detail;

  @override
  Widget build(BuildContext context) {
    final limits = detail.entitlements.limits;

    return DashboardPanel(
      sectionId: DashboardSectionIds.platformLicenseLimits,
      icon: DashboardIcons.usage,
      title: 'الحدود والاستخدام',
      subtitle: detail.overLimits.isEmpty
          ? 'لا تجاوز على أي حد'
          : 'تجاوز ${detail.overLimits.length} حدًّا',
      collapsedSummary: DashboardSectionSummary(
        items: [
          '${limits.length} حد',
          if (detail.overLimits.isNotEmpty) '${detail.overLimits.length} تجاوز',
        ],
      ),
      child: limits.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.usage,
              title: 'لا توجد حدود على هذه الباقة',
            )
          : Column(
              children: [
                for (final limit in limits)
                  UsageBar(
                    label: limit.nameAr,
                    used: limit.used ?? 0,
                    limit: limit.limit,
                    unit: limit.unitAr,
                    dense: true,
                  ),
              ],
            ),
    );
  }
}

/// Every resolved value and the rung that produced it.
///
/// Defaults are hidden by default. An office resolves the whole catalog, and a
/// list where forty rows say «الافتراضي» buries the three that say «استثناء» —
/// which are the only rows anyone opens this panel to find.
class _EffectiveFeaturesSection extends StatefulWidget {
  const _EffectiveFeaturesSection({required this.detail});

  final OfficeLicenseDetail detail;

  @override
  State<_EffectiveFeaturesSection> createState() =>
      _EffectiveFeaturesSectionState();
}

class _EffectiveFeaturesSectionState extends State<_EffectiveFeaturesSection> {
  bool _decisionsOnly = true;

  @override
  Widget build(BuildContext context) {
    final all = widget.detail.entitlements.features.values.toList()
      ..sort((a, b) {
        final byCategory = a.categoryKey.compareTo(b.categoryKey);
        return byCategory != 0
            ? byCategory
            : a.sortOrder.compareTo(b.sortOrder);
      });
    final decided = all.where((f) => f.source != 'default').toList();
    final shown = _decisionsOnly ? decided : all;

    return DashboardPanel(
      sectionId: DashboardSectionIds.platformLicenseFeatures,
      icon: DashboardIcons.featureCatalog,
      title: 'الميزات الفعّالة',
      subtitle: 'كل قيمة ومصدرها — أي رتبة في السلم أنتجتها.',
      collapsedSummary: DashboardSectionSummary(
        items: ['${all.length} ميزة', '${decided.length} بقرار صريح'],
      ),
      trailing: FilterChip(
        label: Text('بقرار صريح فقط (${decided.length})'),
        selected: _decisionsOnly,
        onSelected: (on) => setState(() => _decisionsOnly = on),
      ),
      child: shown.isEmpty
          ? DashboardEmptyState(
              icon: DashboardIcons.featureCatalog,
              title: _decisionsOnly
                  ? 'المكتب يتبع باقته والافتراضيات بالكامل'
                  : 'لا توجد ميزات محلولة',
              message: _decisionsOnly
                  ? 'لا قيمة هنا جاءت من استثناء أو من حالة ترخيص.'
                  : null,
              action: _decisionsOnly
                  ? TextButton(
                      onPressed: () => setState(() => _decisionsOnly = false),
                      child: const Text('عرض كل الميزات'),
                    )
                  : null,
            )
          : Column(
              children: [
                for (final feature in shown)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            feature.nameAr,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            FeatureValue.label(
                              feature.value,
                              unit: feature.unitAr,
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        FeatureSourceChip(
                          source: feature.source,
                          blockedBy: feature.blockedBy,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _OverridesSection extends StatelessWidget {
  const _OverridesSection({required this.state, required this.detail});

  final PlatformLicensingLoaded state;
  final OfficeLicenseDetail detail;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();

    return DashboardPanel(
      sectionId: DashboardSectionIds.platformLicenseOverrides,
      icon: DashboardIcons.locked,
      title: 'الاستثناءات',
      subtitle:
          'استثناءات هذا المكتب وحده. لا تُنشأ باقة جديدة لكل تفاوض — يُنشأ صف.',
      collapsedSummary: DashboardSectionSummary(
        items: [
          detail.overrides.isEmpty
              ? 'لا استثناءات'
              : '${detail.overrides.length} استثناء',
        ],
      ),
      trailing: FilledButton.tonalIcon(
        onPressed: () => _add(context, cubit),
        icon: const Icon(DashboardIcons.add, size: 18),
        label: const Text('استثناء'),
      ),
      child: detail.overrides.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.locked,
              title: 'لا توجد استثناءات',
              message: 'المكتب يتبع باقته بالكامل.',
            )
          : Column(
              children: [
                for (final entry in detail.overrides)
                  OverrideTile(
                    entry: entry,
                    onClear: () => _clear(context, cubit, entry),
                  ),
              ],
            ),
    );
  }

  Future<void> _add(BuildContext context, PlatformLicensingCubit cubit) async {
    final result = await showDialog<_OverrideDraft>(
      context: context,
      builder: (context) => _OverrideDialog(catalog: state.catalog),
    );
    if (result == null || !context.mounted) return;
    await cubit.setOverride(
      detail.officeId,
      result.featureKey,
      result.value,
      result.reason,
      expiresAt: result.expiresAt,
    );
  }

  Future<void> _clear(
    BuildContext context,
    PlatformLicensingCubit cubit,
    FeatureOverride entry,
  ) async {
    final reason = await promptForReason(
      context,
      title: 'إزالة الاستثناء',
      description:
          'سيعود «${entry.nameAr}» إلى قيمة الباقة. الإزالة مسجَّلة في السجل.',
      confirmLabel: 'إزالة',
      suggestions: const [
        'انتهت المدة المتفق عليها للاستثناء',
        'المكتب انتقل إلى باقة تغطيه',
        'أُنشئ بالخطأ',
      ],
    );
    if (reason == null || !context.mounted) return;
    await cubit.clearOverride(detail.officeId, entry.featureKey, reason);
  }
}

class _OverrideDraft {
  const _OverrideDraft({
    required this.featureKey,
    required this.value,
    required this.reason,
    this.expiresAt,
  });

  final String featureKey;
  final Object? value;
  final String reason;
  final DateTime? expiresAt;
}

class _OverrideDialog extends StatefulWidget {
  const _OverrideDialog({required this.catalog});

  final FeatureCatalog catalog;

  @override
  State<_OverrideDialog> createState() => _OverrideDialogState();
}

class _OverrideDialogState extends State<_OverrideDialog> {
  CatalogFeature? _feature;
  Object? _value;
  DateTime? _expiresAt;
  final _reason = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final features =
        widget.catalog.features.where((f) => f.status != 'hidden').toList()
          ..sort((a, b) => a.nameAr.compareTo(b.nameAr));

    return AlertDialog(
      title: const Text('استثناء لهذا المكتب'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _feature?.key,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'الميزة',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final f in features)
                      DropdownMenuItem(value: f.key, child: Text(f.nameAr)),
                  ],
                  validator: (v) => v == null ? 'اختر ميزة' : null,
                  onChanged: (key) => setState(() {
                    _feature = features.firstWhere((f) => f.key == key);
                    _value = _feature!.defaultValue;
                  }),
                ),
                if (_feature != null) ...[
                  const SizedBox(height: AppSpacing.medium),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.small),
                    decoration: BoxDecoration(
                      color: DashboardColors.well(context),
                      borderRadius: BorderRadius.circular(
                        AppTokens.radiusSmall,
                      ),
                      border: Border.all(
                        color: DashboardColors.border(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(child: Text('القيمة لهذا المكتب')),
                        FeatureValueField(
                          feature: _feature!,
                          value: _value,
                          onChanged: (v) => setState(() => _value = v),
                        ),
                      ],
                    ),
                  ),
                  if (_feature!.requires.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.small),
                      child: LicensingNotice(
                        icon: DashboardIcons.attention,
                        color: Theme.of(context).colorScheme.tertiary,
                        // The trap worth naming before they hit it.
                        message:
                            'تتطلب: ${_feature!.requires.join('، ')}. الاستثناء '
                            'يُحترم لكن التبعية تُسقِطه إن لم تكن مفعّلة.',
                      ),
                    ),
                ],
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _reason,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'السبب',
                    hintText: 'تنازل تجاري، تمديد، تعويض…',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v ?? '').trim().length < 8
                      ? 'اكتب سببًا واضحًا (٨ أحرف على الأقل)'
                      : null,
                ),
                const SizedBox(height: AppSpacing.small),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _expiresAt == null
                            ? 'دائم — لا ينتهي تلقائيًا'
                            : 'ينتهي في ${licensingDate(_expiresAt)}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 1095),
                          ),
                          initialDate: DateTime.now().add(
                            const Duration(days: 90),
                          ),
                        );
                        if (picked != null) setState(() => _expiresAt = picked);
                      },
                      child: const Text('تحديد انتهاء'),
                    ),
                    if (_expiresAt != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _expiresAt = null),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop(
              _OverrideDraft(
                featureKey: _feature!.key,
                value: _value,
                reason: _reason.text.trim(),
                expiresAt: _expiresAt,
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class _InvoicesSection extends StatelessWidget {
  const _InvoicesSection({required this.detail});

  final OfficeLicenseDetail detail;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      sectionId: DashboardSectionIds.platformLicenseBilling,
      icon: DashboardIcons.billing,
      title: 'الفوترة',
      subtitle: detail.invoices.isEmpty
          ? 'لا فواتير بعد'
          : '${detail.invoices.length} فاتورة',
      collapsedSummary: DashboardSectionSummary(
        items: ['${detail.invoices.length} فاتورة'],
      ),
      child: detail.invoices.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.billing,
              title: 'لا توجد فواتير',
              message: 'التحصيل يدوي في هذا الإصدار — أصدر فاتورة من الأعلى.',
            )
          : Column(
              children: [
                for (final invoice in detail.invoices)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(invoice.invoiceNumber),
                    subtitle: Text(
                      '${licensingDate(invoice.periodStart)} → '
                      '${licensingDate(invoice.periodEnd)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(licensingMoney(invoice.total, invoice.currency)),
                        const SizedBox(width: AppSpacing.small),
                        StatusChip(label: invoice.statusLabelAr),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.detail});

  final OfficeLicenseDetail detail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return DashboardPanel(
      sectionId: DashboardSectionIds.platformLicenseActivity,
      icon: DashboardIcons.audit,
      // Reference material, not a decision: it opens only when asked for.
      initiallyExpanded: false,
      title: 'النشاط',
      subtitle: 'شريحة هذا المكتب من سجل التغييرات.',
      collapsedSummary: DashboardSectionSummary(
        items: [
          detail.activity.isEmpty
              ? 'لا تغييرات'
              : '${detail.activity.length} تغيير',
          if (detail.activity.isNotEmpty)
            'آخرها ${licensingDate(detail.activity.first.createdAt)}',
        ],
      ),
      child: detail.activity.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.audit,
              title: 'لا توجد تغييرات مسجّلة',
            )
          : Column(
              children: [
                for (final entry in detail.activity.take(20))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 92,
                          child: Text(
                            licensingDate(entry.createdAt),
                            style: text.labelSmall?.copyWith(
                              color: DashboardColors.mutedInk(context),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${entry.actionLabelAr} — ${entry.entityLabelAr} '
                            '«${entry.entityRef}»'
                            '${entry.reason.isEmpty ? '' : ' · ${entry.reason}'}',
                            style: text.bodySmall,
                          ),
                        ),
                        Text(
                          entry.actorLabel,
                          style: text.labelSmall?.copyWith(
                            color: DashboardColors.mutedInk(context),
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
