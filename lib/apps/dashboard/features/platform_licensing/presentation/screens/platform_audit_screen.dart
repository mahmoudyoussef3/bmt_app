import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/ui_state/dashboard_section_state_store.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_module_header.dart';
import '../../../../core/widgets/dashboard_panel.dart';
import '../../domain/entities/office_license.dart';
import '../cubit/platform_licensing_cubit.dart';
import '../widgets/audit_trail_widgets.dart';
import '../widgets/licensing_scaffold.dart';

/// The entity families the trail can be narrowed to, in the order an operator
/// looks for them. Filtering happens server-side, so a narrower family also
/// reaches further back than the read cap.
const _entityTypes = <String?, String>{
  null: 'الكل',
  'license': 'التراخيص',
  'override': 'الاستثناءات',
  'plan': 'الباقات',
  'plan_feature': 'قيم الباقات',
  'feature': 'الميزات',
  'invoice': 'الفواتير',
  'settings': 'الإعدادات',
};

const _periods = <int?, String>{
  null: 'كل الفترة',
  1: 'اليوم',
  7: '٧ أيام',
  30: '٣٠ يومًا',
};

/// سجل التغييرات — the licensing decision trail.
///
/// Written by database triggers rather than by application code, because an
/// audit log a caller can forget to write is not an audit log. It is
/// append-only: the API roles cannot UPDATE or DELETE it, and a trigger refuses
/// both even for the table owner — so removing evidence requires a schema
/// change, which is itself visible.
///
/// It is presented as a **day-grouped trail**, not a grid. The grid it replaced
/// spent five of its seven columns on machine references (`max_captains`,
/// `true`, a bare office uuid) and dashes, printed a date but never a time, and
/// never showed the one thing an audit row exists for — the value before and
/// after. Every row here reads as a sentence, and the evidence behind it opens
/// in place.
class PlatformAuditScreen extends StatefulWidget {
  const PlatformAuditScreen({super.key});

  @override
  State<PlatformAuditScreen> createState() => _PlatformAuditScreenState();
}

class _PlatformAuditScreenState extends State<PlatformAuditScreen> {
  /// How many rows more the trail reveals per press. Progressive disclosure
  /// rather than page flipping: a chronological trail read in pages loses the
  /// operator's place every time the day boundary lands mid-page.
  static const _step = 30;

  /// The read limit `GetLicenseAuditUseCase` asks the RPC for. Named here so
  /// the screen can say so out loud instead of implying it is showing
  /// everything.
  static const _serverCap = 100;

  String? _entityType;
  int? _sinceDays;
  String _query = '';
  int _visible = _step;

  /// Both filters are server-side: the RPC returns the most recent rows that
  /// match, so narrowing is also how the operator reaches past the read cap.
  void _pushFilters(PlatformLicensingCubit cubit) {
    final since = _sinceDays;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    cubit.loadAudit(
      filters: {
        if (_entityType != null) 'entity_type': _entityType,
        if (since != null)
          'since': startOfToday
              .subtract(Duration(days: since - 1))
              .toUtc()
              .toIso8601String(),
      },
    );
    setState(() => _visible = _step);
  }

  List<LicenseAuditEntry> _search(
    List<LicenseAuditEntry> rows,
    AuditLabels labels,
  ) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((entry) {
      bool hit(String value) => value.toLowerCase().contains(q);
      return hit(labels.subject(entry)) ||
          hit(entry.officeName ?? '') ||
          hit(entry.actorLabel) ||
          hit(entry.reason) ||
          hit(entry.entityRef) ||
          hit(entry.actionLabelAr) ||
          hit(entry.entityLabelAr);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LicensingScreenFrame(
      builder: (context, state) {
        final cubit = context.read<PlatformLicensingCubit>();
        final labels = AuditLabels(
          features: state.catalog.features,
          plans: state.plans,
        );
        final matches = _search(state.audit, labels);
        final shown = matches.take(_visible).toList();

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _AuditHeader(
              entityType: _entityType,
              sinceDays: _sinceDays,
              query: _query,
              onEntityType: (value) {
                _entityType = value;
                _pushFilters(cubit);
              },
              onPeriod: (value) {
                _sinceDays = value;
                _pushFilters(cubit);
              },
              onQuery: (value) => setState(() {
                _query = value;
                _visible = _step;
              }),
              onRefresh: () => _pushFilters(cubit),
            ),
            const SizedBox(height: AppSpacing.medium),
            DashboardPanel(
              sectionId: DashboardSectionIds.platformAuditLog,
              icon: DashboardIcons.audit,
              title: 'القرارات',
              subtitle: _subtitle(matches),
              child: matches.isEmpty
                  ? _EmptyTrail(
                      filtered:
                          _query.trim().isNotEmpty ||
                          _entityType != null ||
                          _sinceDays != null,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final group in groupAuditByDay(shown)) ...[
                          AuditDayHeader(
                            day: group.day,
                            count: group.entries.length,
                          ),
                          // Rows vary in height — some carry a reason, some do
                          // not — so they get the same hairline the console's
                          // tables use rather than relying on rhythm alone.
                          for (final (index, entry)
                              in group.entries.indexed) ...[
                            if (index > 0)
                              Divider(
                                height: 1,
                                color: DashboardColors.divider(context),
                              ),
                            AuditEntryTile(entry: entry, labels: labels),
                          ],
                        ],
                        const SizedBox(height: AppSpacing.small),
                        _TrailFooter(
                          shown: shown.length,
                          matched: matches.length,
                          atServerCap: state.audit.length >= _serverCap,
                          onMore: () => setState(() => _visible += _step),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  String _subtitle(List<LicenseAuditEntry> matches) {
    if (matches.isEmpty) return 'لا تغييرات في هذا النطاق';
    final offices = matches
        .map((e) => e.officeName)
        .whereType<String>()
        .toSet()
        .length;
    return '${matches.length} تغيير'
        '${offices == 0 ? '' : ' · $offices مكتب متأثر'}'
        ' · آخر تغيير ${auditRelative(matches.first.createdAt)}';
  }
}

/// Title, the append-only promise, and the three filters that make a hundred
/// rows answerable.
class _AuditHeader extends StatelessWidget {
  const _AuditHeader({
    required this.entityType,
    required this.sinceDays,
    required this.query,
    required this.onEntityType,
    required this.onPeriod,
    required this.onQuery,
    required this.onRefresh,
  });

  final String? entityType;
  final int? sinceDays;
  final String query;
  final ValueChanged<String?> onEntityType;
  final ValueChanged<int?> onPeriod;
  final ValueChanged<String> onQuery;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return DashboardModuleHeader(
      icon: DashboardIcons.audit,
      title: 'سجل التغييرات',
      subtitle:
          'كل قرار ترخيص: من، ومتى، ولماذا. يُكتب تلقائيًا ولا يقبل '
          'التعديل أو الحذف.',
      actions: [
        TextButton.icon(
          onPressed: onRefresh,
          icon: const Icon(DashboardIcons.refresh, size: 18),
          label: const Text('تحديث'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.small,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: DebouncedSearchField(
                  initialValue: query,
                  hintText: 'ابحث بالمكتب أو المنفِّذ أو السبب…',
                  onChanged: onQuery,
                ),
              ),
              SegmentedButton<int?>(
                showSelectedIcon: false,
                segments: [
                  for (final period in _periods.entries)
                    ButtonSegment(value: period.key, label: Text(period.value)),
                ],
                selected: {sinceDays},
                onSelectionChanged: (selection) => onPeriod(selection.first),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.xSmall,
            runSpacing: AppSpacing.xSmall,
            children: [
              for (final entry in _entityTypes.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  // Single-select: the checkmark a FilterChip adds says
                  // "multiple", which these are not.
                  showCheckmark: false,
                  selected: entityType == entry.key,
                  onSelected: (_) => onEntityType(entry.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTrail extends StatelessWidget {
  const _EmptyTrail({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return DashboardEmptyState(
      icon: DashboardIcons.audit,
      title: filtered ? 'لا نتائج لهذه التصفية' : 'لا توجد تغييرات مسجّلة',
      message: filtered
          ? 'وسّع النطاق الزمني أو اختر «الكل».'
          : 'أول قرار ترخيص سيظهر هنا لحظة اتخاذه.',
    );
  }
}

/// How much of the trail is on screen, and — when the read cap is reached —
/// that there is more behind it. Saying "100 سجل" while the RPC caps a read at
/// 100 would have been the screen quietly claiming that is all there ever was.
class _TrailFooter extends StatelessWidget {
  const _TrailFooter({
    required this.shown,
    required this.matched,
    required this.atServerCap,
    required this.onMore,
  });

  final int shown;
  final int matched;
  final bool atServerCap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final remaining = matched - shown;

    return Column(
      children: [
        if (remaining > 0)
          TextButton.icon(
            onPressed: onMore,
            icon: const Icon(Icons.expand_more_rounded, size: 18),
            label: Text('عرض $remaining تغييرًا أقدم'),
          )
        else if (atServerCap)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
            child: Text(
              'هذه أحدث 100 حركة. للوصول إلى ما قبلها، اختر نوعًا أو نطاقًا '
              'زمنيًا أضيق.',
              textAlign: TextAlign.center,
              style: text.labelSmall?.copyWith(
                color: DashboardColors.mutedInk(context),
              ),
            ),
          ),
        Text(
          'المعروض $shown من $matched',
          style: text.labelSmall?.copyWith(
            color: DashboardColors.faintInk(context),
          ),
        ),
      ],
    );
  }
}
