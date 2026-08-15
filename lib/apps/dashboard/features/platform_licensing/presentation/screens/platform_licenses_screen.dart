import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_panel.dart';
import '../../domain/entities/licensing_catalog.dart';
import '../../domain/entities/office_license.dart';
import '../cubit/platform_licensing_cubit.dart';
import '../cubit/platform_licensing_state.dart';
import '../sections/usage_section.dart';
import '../widgets/assign_plan_dialog.dart';
import '../widgets/licensing_layout.dart';
import '../widgets/licensing_scaffold.dart';
import '../widgets/licensing_widgets.dart';
import '../widgets/office_feature_board.dart';

/// التراخيص — every office's licence, and the one screen that answers
/// "why does this office have this?".
///
/// The answer lives in the `source` of each resolved feature: which rung of the
/// ladder produced the value. That single field is the difference between a
/// two-minute support conversation and a twenty-minute one.
///
/// **Directory → workspace, not master/detail.** The office used to open into a
/// pane worth three fifths of the window, holding six stacked panels — limits,
/// overrides, effective features, invoices, activity — each with its own folding
/// header. Reaching the invoices meant scrolling past everything above them, in
/// a column too narrow for any of it. It now opens full width, and those panels
/// are four tabs: the operator picks the question instead of scrolling past the
/// other three.
///
/// This is the same shape the plan gallery uses, and for the same reason: browse
/// in a grid, work full width. Master/detail is kept only for the feature
/// catalog, which is read, not edited.
///
/// **الاستخدام came home.** The platform-wide usage screen drew the same meters
/// this workspace already had, one office per panel, as its own sidebar row.
/// It is now this workspace's «الاستخدام» tab, and the platform-wide question it
/// used to answer — who is over a limit — is the «تجاوزت حدًّا» signal below,
/// which names the offices and the metrics instead of asking anyone to scan.
///
/// **The office opens on its features.** «الميزات والحدود» is the first tab and
/// the reason most operators come here: every catalogued feature, a switch, and
/// the numeric ceilings editable in place. It replaced a read-only «الميزات
/// الفعّالة» list beside an «الاستثناءات» tab whose only way to change anything
/// was a dialog with a forty-seven-item dropdown — two tabs to answer one
/// question, and neither of them where the answer was acted on.
class PlatformLicensesScreen extends StatefulWidget {
  const PlatformLicensesScreen({super.key});

  @override
  State<PlatformLicensesScreen> createState() => _PlatformLicensesScreenState();
}

class _PlatformLicensesScreenState extends State<PlatformLicensesScreen> {
  String _query = '';

  /// The alert whose office list is open, if any. One at a time: two open lists
  /// push the directory off the screen, which is the problem the strip had.
  String? _openAlert;

  /// The open tab of the office workspace, and the office it belongs to — so
  /// moving to a different office starts on «الميزات والحدود» rather than on
  /// whichever tab the previous office was left on.
  int _tab = 0;
  String? _openOfficeId;

  /// The feature board's unsaved edits, keyed by feature key.
  ///
  /// Held here rather than inside the board for the reason the plan editor's
  /// buffer is held in its section: this widget owns the navigation away from
  /// the office, and a draft owned by the board is a draft that navigation can
  /// only discard silently.
  Map<String, OfficeFeatureEdit> _featureDraft = {};

  /// The one reason the whole batch is saved under. `platform_set_override`
  /// refuses anything under eight characters, so this is required rather than
  /// the optional note the plan editor carries.
  final TextEditingController _reason = TextEditingController();
  bool _showReasonError = false;

  /// Bumped whenever the buffer is dropped, so the board's text fields rebuild
  /// from the office's real values instead of keeping what was typed into a
  /// draft that no longer exists.
  int _draftGeneration = 0;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  /// Re-points the workspace when — and only when — the operator moved to a
  /// different office, so a background refresh cannot silently discard edits.
  ///
  /// Assigns during build without `setState` deliberately, the same way the plan
  /// section re-points its buffer: the frame being built is the one that needs
  /// the new value, and the assignment is idempotent for a given selection.
  void _syncOffice(OfficeLicenseDetail? detail) {
    if (detail == null) {
      _openOfficeId = null;
      return;
    }
    if (detail.officeId != _openOfficeId) {
      _openOfficeId = detail.officeId;
      _tab = 0;
      _dropDraft();
    }
  }

  void _dropDraft() {
    _featureDraft = {};
    _reason.clear();
    _showReasonError = false;
    _draftGeneration++;
  }

  @override
  Widget build(BuildContext context) {
    return LicensingScreenFrame(
      builder: (context, state) {
        final detail = state.selectedOffice;
        _syncOffice(detail);

        if (detail == null) {
          return _LicenseDirectory(
            state: state,
            query: _query,
            openAlert: _openAlert,
            onQuery: (q) => setState(() => _query = q),
            onToggleAlert: (key) =>
                setState(() => _openAlert = _openAlert == key ? null : key),
          );
        }

        return _OfficeWorkspace(
          state: state,
          detail: detail,
          tab: _tab,
          draft: _featureDraft,
          generation: _draftGeneration,
          reason: _reason,
          showReasonError: _showReasonError,
          onTab: (index) => setState(() => _tab = index),
          onEdit: (edit) =>
              setState(() => _featureDraft[edit.featureKey] = edit),
          onDropEdit: (key) => setState(() => _featureDraft.remove(key)),
          onDiscard: () => setState(_dropDraft),
          onApply: (changes) => _apply(context, detail, changes),
          onReasonChanged: (value) {
            if (_showReasonError && value.trim().length >= 8) {
              setState(() => _showReasonError = false);
            }
          },
          onBack: () => _closeOffice(context, detail, state),
        );
      },
    );
  }

  Future<void> _apply(
    BuildContext context,
    OfficeLicenseDetail detail,
    OfficeFeatureChanges changes,
  ) async {
    final cubit = context.read<PlatformLicensingCubit>();
    final reason = _reason.text.trim();
    if (reason.length < 8) {
      setState(() => _showReasonError = true);
      return;
    }

    // Dropped before the call, not after: every RPC returns the office's whole
    // resolved document, so once the batch is away the board draws the server's
    // answer — including the rows a partial failure did not reach.
    setState(_dropDraft);
    await cubit.applyFeatureEdits(detail.officeId, changes.edits, reason);
  }

  Future<void> _closeOffice(
    BuildContext context,
    OfficeLicenseDetail detail,
    PlatformLicensingLoaded state,
  ) async {
    final cubit = context.read<PlatformLicensingCubit>();
    final pending = resolveOfficeFeatureChanges(
      detail: detail,
      catalog: state.catalog,
      draft: _featureDraft,
    );

    if (pending.isNotEmpty) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تغييرات غير محفوظة'),
          content: Text(
            'على «${detail.officeName}» ${pending.edits.length} تغيير لم '
            'يُطبَّق. الخروج من المكتب يتخلّى عنها.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('البقاء هنا'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('تجاهل والخروج'),
            ),
          ],
        ),
      );
      if (leave != true) return;
    }

    if (!mounted) return;
    setState(_dropDraft);
    cubit.clearOfficeSelection();
  }
}

// ---------------------------------------------------------------------------
// Directory
// ---------------------------------------------------------------------------

const Map<String?, String> _statusLabels = {
  null: 'الكل',
  'active': 'نشطة',
  'trialing': 'تجريبية',
  'past_due': 'متأخرة',
  'grace': 'مهلة',
  'suspended': 'موقوفة',
  'expired': 'منتهية',
};

class _LicenseDirectory extends StatelessWidget {
  const _LicenseDirectory({
    required this.state,
    required this.query,
    required this.openAlert,
    required this.onQuery,
    required this.onToggleAlert,
  });

  final PlatformLicensingLoaded state;
  final String query;
  final String? openAlert;
  final ValueChanged<String> onQuery;
  final ValueChanged<String> onToggleAlert;

  List<OfficeLicenseRow> get _visible {
    final q = query.trim().toLowerCase();
    return state.visibleLicenses.where((row) {
      if (q.isEmpty) return true;
      return row.officeName.toLowerCase().contains(q) ||
          row.planNameAr.contains(q) ||
          row.officeSlug.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final rows = _visible;
    final total = state.licenses.length;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _DirectoryHeader(state: state),
        const SizedBox(height: AppSpacing.medium),
        _AlertStrip(state: state, openKey: openAlert, onToggle: onToggleAlert),
        const SizedBox(height: AppSpacing.medium),
        LicensingToolbar(
          search: DebouncedSearchField(
            initialValue: query,
            hintText: 'ابحث باسم المكتب أو باقته',
            onChanged: onQuery,
          ),
          filters: [
            for (final entry in _statusLabels.entries)
              if (entry.key == null ||
                  state.licenses.any((l) => l.status == entry.key))
                FilterChip(
                  label: Text(
                    entry.key == null
                        ? '${entry.value} ($total)'
                        : '${entry.value} '
                              '(${state.licenses.where((l) => l.status == entry.key).length})',
                  ),
                  selected: state.licenseStatusFilter == entry.key,
                  onSelected: (_) => cubit.filterLicenses(entry.key),
                ),
          ],
          trailing: Text(
            rows.length == total ? '$total مكتب' : '${rows.length} من $total',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        if (rows.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: DashboardEmptyState(
              icon: DashboardIcons.licenses,
              title: total == 0 ? 'لا يوجد مكتب مرخَّص' : 'لا مكتب مطابق',
              message: total == 0
                  ? 'يظهر المكتب هنا فور إنشائه من «مكاتب المنصة».'
                  : 'جرّب اسمًا آخر أو أزل تصفية الحالة.',
              action: total == 0
                  ? null
                  : TextButton(
                      onPressed: () {
                        onQuery('');
                        cubit.filterLicenses(null);
                      },
                      child: const Text('عرض كل المكاتب'),
                    ),
            ),
          )
        else
          LicensingCardGrid(
            minCardWidth: 330,
            maxColumns: 3,
            children: [
              for (final row in rows)
                _OfficeCard(
                  row: row,
                  onOpen: () => cubit.selectOffice(row.officeId),
                ),
            ],
          ),
      ],
    );
  }
}

class _DirectoryHeader extends StatelessWidget {
  const _DirectoryHeader({required this.state});

  final PlatformLicensingLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();
    final scheme = Theme.of(context).colorScheme;
    final licenses = state.licenses;
    final active = licenses.where((l) => l.status == 'active').length;
    final trialing = licenses.where((l) => l.status == 'trialing').length;

    return LicensingConsoleHeader(
      icon: DashboardIcons.licenses,
      title: 'التراخيص',
      subtitle:
          'الحالة التجارية لكل مكتب، وما تسمح به فعليًا. افتح مكتبًا لترى '
          'حدوده واستهلاكه واستثناءاته وفواتيره في مكان واحد.',
      actions: [
        OutlinedButton.icon(
          onPressed: cubit.runLifecycle,
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('تشغيل دورة الحياة'),
        ),
      ],
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
      child: _EnforcementModeBar(state: state),
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

/// One office, the way the plan gallery shows one plan.
///
/// The row it replaced carried a name, a plan and a status chip; everything
/// else about the licence — what it costs, when it renews, whether it is
/// trialing out this week — needed the detail pane. The card carries the
/// commercial facts, so the directory answers most questions without opening
/// anything.
class _OfficeCard extends StatelessWidget {
  const _OfficeCard({required this.row, required this.onOpen});

  final OfficeLicenseRow row;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = switch (row.status) {
      'active' => scheme.secondary,
      'trialing' || 'past_due' || 'grace' => scheme.tertiary,
      'suspended' || 'cancelled' || 'expired' => scheme.error,
      _ => scheme.outline,
    };

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTokens.radius),
                topRight: Radius.circular(AppTokens.radius),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.officeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      LicenseStatusChip(
                        status: row.status,
                        label: row.statusLabelAr,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.planNameAr.isEmpty ? 'بلا باقة' : row.planNameAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: row.planNameAr.isEmpty
                          ? scheme.error
                          : DashboardColors.mutedInk(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    licensingMoney(row.price, row.currency),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Wrap(
                    spacing: AppSpacing.xSmall,
                    runSpacing: AppSpacing.xSmall,
                    children: [
                      LicensingFact(
                        icon: DashboardIcons.time,
                        label:
                            row.trialEndsAt != null && row.status == 'trialing'
                            ? 'التجربة حتى ${licensingDate(row.trialEndsAt)}'
                            : 'حتى ${licensingDate(row.periodEnd)}',
                      ),
                      if (row.overrideCount > 0)
                        LicensingFact(
                          icon: DashboardIcons.locked,
                          label: '${row.overrideCount} استثناء',
                        ),
                      if (row.overLimitCount > 0)
                        LicensingFact(
                          icon: DashboardIcons.usage,
                          label: 'تجاوز ${row.overLimitCount} حدًّا',
                          color: scheme.error,
                        ),
                      if (row.isDelisted)
                        LicensingFact(
                          icon: DashboardIcons.locked,
                          label: 'محجوب عن العملاء',
                          color: scheme.error,
                        ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpacing.medium),
                  Divider(height: 1, color: DashboardColors.divider(context)),
                  const SizedBox(height: AppSpacing.small),
                  FilledButton.tonalIcon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('فتح الترخيص'),
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

// ---------------------------------------------------------------------------
// Alerts
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Workspace
// ---------------------------------------------------------------------------

/// One office, full width: identity and every action always visible, and the
/// four bodies of evidence behind four tabs.
///
/// The save bar floats over all four rather than living inside the board's tab.
/// Unsaved feature edits survive a look at the invoices, and a change buffer
/// that disappears the moment the operator checks something else is a change
/// buffer that loses work.
class _OfficeWorkspace extends StatelessWidget {
  const _OfficeWorkspace({
    required this.state,
    required this.detail,
    required this.tab,
    required this.draft,
    required this.generation,
    required this.reason,
    required this.showReasonError,
    required this.onTab,
    required this.onEdit,
    required this.onDropEdit,
    required this.onDiscard,
    required this.onApply,
    required this.onReasonChanged,
    required this.onBack,
  });

  final PlatformLicensingLoaded state;
  final OfficeLicenseDetail detail;
  final int tab;
  final Map<String, OfficeFeatureEdit> draft;
  final int generation;
  final TextEditingController reason;
  final bool showReasonError;
  final ValueChanged<int> onTab;
  final void Function(OfficeFeatureEdit edit) onEdit;
  final ValueChanged<String> onDropEdit;
  final VoidCallback onDiscard;
  final ValueChanged<OfficeFeatureChanges> onApply;
  final ValueChanged<String> onReasonChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final usageRow = state.usage
        .where((row) => row.officeId == detail.officeId)
        .firstOrNull;
    final enabled = detail.entitlements.features.values
        .where((f) => f.isOn)
        .length;
    final changes = resolveOfficeFeatureChanges(
      detail: detail,
      catalog: state.catalog,
      draft: draft,
    );

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              bottom: changes.isEmpty
                  ? 0.0
                  : (constraints.maxWidth < 780 ? 236.0 : 140.0),
            ),
            children: [
              _OfficeHeader(state: state, detail: detail, onBack: onBack),
              const SizedBox(height: AppSpacing.medium),
              LicensingTabs(
                selected: tab,
                onChanged: onTab,
                tabs: [
                  LicensingTab(
                    label: 'الميزات والحدود',
                    icon: DashboardIcons.featureCatalog,
                    count: enabled,
                  ),
                  LicensingTab(
                    label: 'الاستخدام',
                    icon: DashboardIcons.usage,
                    count:
                        usageRow?.metrics.length ??
                        detail.entitlements.limits.length,
                  ),
                  LicensingTab(
                    label: 'الاستثناءات',
                    icon: DashboardIcons.locked,
                    count: detail.overrides.length,
                  ),
                  LicensingTab(
                    label: 'الفوترة والنشاط',
                    icon: DashboardIcons.billing,
                    count: detail.invoices.length,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              switch (tab) {
                1 => DashboardPanel(
                  icon: DashboardIcons.usage,
                  title: 'الاستخدام',
                  subtitle: detail.overLimits.isEmpty
                      ? 'لا تجاوز على أي حد'
                      : 'تجاوز ${detail.overLimits.length} حدًّا',
                  child: OfficeUsagePanel(detail: detail, row: usageRow),
                ),
                2 => _OverridesTab(state: state, detail: detail),
                3 => _BillingAndActivityTab(detail: detail),
                _ => OfficeFeatureBoard(
                  detail: detail,
                  catalog: state.catalog,
                  usage: usageRow,
                  draft: draft,
                  generation: generation,
                  onEdit: onEdit,
                  onDropEdit: onDropEdit,
                ),
              },
            ],
          ),
          if (changes.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.medium,
              child: OfficeFeatureSaveBar(
                edits: changes.edits,
                summary: changes.summary,
                reasonController: reason,
                showReasonError: showReasonError,
                isBusy: state.isBusy,
                onDiscard: onDiscard,
                onApply: () => onApply(changes),
                onReasonChanged: onReasonChanged,
              ),
            ),
        ],
      ),
    );
  }
}

/// The office's licence, its facts, and every action that can be taken on it.
///
/// The actions used to live behind a `⋯` in a panel header — «تعيين باقة», the
/// single most common operation on this screen, took two clicks and prior
/// knowledge of where it hid.
class _OfficeHeader extends StatelessWidget {
  const _OfficeHeader({
    required this.state,
    required this.detail,
    required this.onBack,
  });

  final PlatformLicensingLoaded state;
  final OfficeLicenseDetail detail;

  /// Routed through the screen rather than straight to the cubit: leaving with
  /// unsaved feature edits has to ask first.
  final VoidCallback onBack;

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
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('كل المكاتب'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
          const SizedBox(height: AppSpacing.small),
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

/// The record of this office's exceptions: who granted what, why, and until
/// when.
///
/// It survived the feature board because the board answers a different
/// question. The board says *what this office has right now* and changes it;
/// this says *what was decided about it*, including the expired concessions
/// that no longer apply and are kept precisely because they happened.
class _OverridesTab extends StatelessWidget {
  const _OverridesTab({required this.state, required this.detail});

  final PlatformLicensingLoaded state;
  final OfficeLicenseDetail detail;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlatformLicensingCubit>();

    return DashboardPanel(
      icon: DashboardIcons.locked,
      title: 'الاستثناءات',
      subtitle:
          'استثناءات هذا المكتب وحده. لا تُنشأ باقة جديدة لكل تفاوض — يُنشأ صف.',
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

/// What this office was charged, and what was decided about it — the two
/// histories, side by side, because a question about one is usually answered by
/// the other.
class _BillingAndActivityTab extends StatelessWidget {
  const _BillingAndActivityTab({required this.detail});

  final OfficeLicenseDetail detail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardPanel(
          icon: DashboardIcons.billing,
          title: 'الفوترة',
          subtitle: detail.invoices.isEmpty
              ? 'لا فواتير بعد'
              : '${detail.invoices.length} فاتورة',
          child: detail.invoices.isEmpty
              ? const DashboardEmptyState(
                  icon: DashboardIcons.billing,
                  title: 'لا توجد فواتير',
                  message:
                      'التحصيل يدوي في هذا الإصدار — أصدر فاتورة من الأعلى.',
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
                            Text(
                              licensingMoney(invoice.total, invoice.currency),
                            ),
                            const SizedBox(width: AppSpacing.small),
                            StatusChip(label: invoice.statusLabelAr),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.medium),
        DashboardPanel(
          icon: DashboardIcons.audit,
          title: 'النشاط',
          subtitle: 'شريحة هذا المكتب من سجل التغييرات.',
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
        ),
      ],
    );
  }
}
