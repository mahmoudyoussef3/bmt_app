import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';

import '../../domain/entities/referral_reward_transaction.dart';
import 'referral_format.dart';
import 'package:bmt_app/core/theme/tokens.dart';

class ReferralTransactionsTab extends StatefulWidget {
  const ReferralTransactionsTab({super.key, required this.transactions});

  final List<ReferralRewardTransaction> transactions;

  @override
  State<ReferralTransactionsTab> createState() =>
      _ReferralTransactionsTabState();
}

class _ReferralTransactionsTabState extends State<ReferralTransactionsTab> {
  String _query = '';
  String? _role;
  int _page = 0;
  static const _pageSize = 12;

  List<ReferralRewardTransaction> get _filtered {
    final q = _query.trim();
    return widget.transactions.where((t) {
      final matchesQuery =
          q.isEmpty ||
          t.userName.contains(q) ||
          t.referralId.contains(q) ||
          t.userId.contains(q);
      final matchesRole = _role == null || t.role == _role;
      return matchesQuery && matchesRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final start = _page * _pageSize;
    final pageItems = filtered.skip(start).take(_pageSize).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withAlpha(80),
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(color: scheme.outline.withAlpha(60)),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.small),
              const Expanded(
                child: Text(
                  'هذا السجل للقراءة فقط — يوثّق كل مكافأة مُنحت ولا يمكن تعديله.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                onChanged: (v) => setState(() {
                  _query = v;
                  _page = 0;
                }),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'ابحث بالمستخدم أو رقم الإحالة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  _Chip(
                    label: 'الكل',
                    selected: _role == null,
                    onTap: () => setState(() => _role = null),
                  ),
                  _Chip(
                    label: 'المُحيل',
                    selected: _role == 'referrer',
                    onTap: () => setState(() => _role = 'referrer'),
                  ),
                  _Chip(
                    label: 'المدعو',
                    selected: _role == 'referred',
                    onTap: () => setState(() => _role = 'referred'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        if (filtered.isEmpty)
          const AppCard(child: Center(child: Text('لا توجد حركات مكافآت.')))
        else
          OpsDataTable(
            columns: const [
              OpsColumn('المستخدم', flex: 2, minWidth: 120),
              OpsColumn('الدور', flex: 1, minWidth: 80),
              OpsColumn('نوع المكافأة', flex: 2, minWidth: 110),
              OpsColumn('القيمة', flex: 1, numeric: true, minWidth: 80),
              OpsColumn('الحالة', flex: 1, minWidth: 90),
              OpsColumn('رقم الإحالة', flex: 2, minWidth: 120),
              OpsColumn('التاريخ', flex: 2, minWidth: 110),
            ],
            rows: [
              for (final t in pageItems)
                [
                  Text(
                    t.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(t.role == 'referred' ? 'المدعو' : 'المُحيل'),
                  Text(referralRewardTypeLabel(t.rewardType)),
                  Text(referralArNum(t.rewardValue)),
                  Text(t.status == 'granted' ? 'ممنوحة' : t.status),
                  Text(
                    t.referralId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(referralArDate(t.createdAt)),
                ],
            ],
            total: filtered.length,
            currentPage: _page,
            pageSize: _pageSize,
            onPageChanged: (p) => setState(() => _page = p),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
