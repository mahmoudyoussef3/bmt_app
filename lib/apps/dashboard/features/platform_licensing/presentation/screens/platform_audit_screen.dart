import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../../../core/theme/dashboard_colors.dart';
import '../../../../core/theme/dashboard_icons.dart';
import '../../../../core/widgets/dashboard_empty_state.dart';
import '../../../../core/widgets/dashboard_module_header.dart';
import '../../../../core/widgets/dashboard_panel.dart';
import '../../../../core/widgets/ops_data_table.dart';
import '../cubit/platform_licensing_cubit.dart';
import '../widgets/licensing_scaffold.dart';
import '../widgets/licensing_widgets.dart';

/// سجل التغييرات — the licensing decision trail.
///
/// Written by database triggers rather than by application code, because an
/// audit log a caller can forget to write is not an audit log. It is
/// append-only: the API roles cannot UPDATE or DELETE it, and a trigger refuses
/// both even for the table owner — so removing evidence requires a schema
/// change, which is itself visible.
class PlatformAuditScreen extends StatefulWidget {
  const PlatformAuditScreen({super.key});

  @override
  State<PlatformAuditScreen> createState() => _PlatformAuditScreenState();
}

class _PlatformAuditScreenState extends State<PlatformAuditScreen> {
  int _page = 0;
  String? _entityType;
  static const _pageSize = 20;

  static const _entityTypes = <String?, String>{
    null: 'الكل',
    'license': 'التراخيص',
    'override': 'الاستثناءات',
    'plan': 'الباقات',
    'plan_feature': 'قيم الباقات',
    'feature': 'الميزات',
    'invoice': 'الفواتير',
    'settings': 'الإعدادات',
  };

  @override
  Widget build(BuildContext context) {
    return LicensingScreenFrame(
      builder: (context, state) {
        final cubit = context.read<PlatformLicensingCubit>();
        final entries = state.audit;
        final pageRows = entries
            .skip(_page * _pageSize)
            .take(_pageSize)
            .toList();
        final text = Theme.of(context).textTheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardModuleHeader(
              icon: DashboardIcons.audit,
              title: 'سجل التغييرات',
              subtitle:
                  'كل قرار ترخيص: من، ومتى، ولماذا. يُكتب تلقائيًا ولا يقبل '
                  'التعديل أو الحذف.',
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in _entityTypes.entries)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.xSmall,
                          ),
                          child: FilterChip(
                            label: Text(entry.value),
                            selected: _entityType == entry.key,
                            onSelected: (_) {
                              setState(() {
                                _entityType = entry.key;
                                _page = 0;
                              });
                              cubit.loadAudit(
                                filters: entry.key == null
                                    ? const {}
                                    : {'entity_type': entry.key},
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Expanded(
              child: DashboardPanel(
                icon: DashboardIcons.audit,
                title: 'القرارات',
                subtitle: '${entries.length} سجل',
                child: entries.isEmpty
                    ? const DashboardEmptyState(
                        icon: DashboardIcons.audit,
                        title: 'لا توجد سجلات',
                      )
                    : OpsDataTable(
                        columns: const [
                          OpsColumn('التاريخ', flex: 2),
                          OpsColumn('المكتب', flex: 2),
                          OpsColumn('النوع', flex: 2),
                          OpsColumn('الإجراء', flex: 2),
                          OpsColumn('العنصر', flex: 2),
                          OpsColumn('السبب', flex: 3),
                          OpsColumn('المنفِّذ', flex: 2),
                        ],
                        rows: [
                          for (final entry in pageRows)
                            [
                              Text(
                                licensingDate(entry.createdAt),
                                style: text.bodySmall,
                              ),
                              Text(
                                entry.officeName ?? '—',
                                style: text.bodySmall,
                              ),
                              StatusChip(label: entry.entityLabelAr),
                              Text(entry.actionLabelAr, style: text.bodySmall),
                              Text(entry.entityRef, style: text.bodySmall),
                              Text(
                                entry.reason.isEmpty ? '—' : entry.reason,
                                style: text.bodySmall?.copyWith(
                                  color: DashboardColors.mutedInk(context),
                                ),
                              ),
                              Text(entry.actorLabel, style: text.bodySmall),
                            ],
                        ],
                        total: entries.length,
                        currentPage: _page,
                        pageSize: _pageSize,
                        onPageChanged: (page) => setState(() => _page = page),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
