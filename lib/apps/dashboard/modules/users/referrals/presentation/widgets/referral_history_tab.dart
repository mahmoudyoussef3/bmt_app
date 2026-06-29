import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';

import '../../domain/entities/referral_record.dart';
import 'referral_format.dart';
import 'referral_status_chip.dart';

class ReferralHistoryTab extends StatefulWidget {
  const ReferralHistoryTab({super.key, required this.records});

  final List<ReferralRecord> records;

  @override
  State<ReferralHistoryTab> createState() => _ReferralHistoryTabState();
}

class _ReferralHistoryTabState extends State<ReferralHistoryTab> {
  String _query = '';
  ReferralStatus? _status;
  String? _rewardStatus;
  DateTimeRange? _range;
  int _page = 0;
  static const _pageSize = 12;

  List<ReferralRecord> get _filtered {
    final q = _query.trim();
    return widget.records.where((r) {
      final matchesQuery =
          q.isEmpty ||
          r.code.contains(q.toUpperCase()) ||
          r.referrerName.contains(q) ||
          r.referredName.contains(q);
      final matchesStatus = _status == null || r.status == _status;
      final matchesReward =
          _rewardStatus == null || r.rewardStatus == _rewardStatus;
      final matchesRange =
          _range == null ||
          (!r.createdAt.isBefore(_range!.start) &&
              !r.createdAt.isAfter(_range!.end.add(const Duration(days: 1))));
      return matchesQuery && matchesStatus && matchesReward && matchesRange;
    }).toList();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final start = _page * _pageSize;
    final pageItems = filtered.skip(start).take(_pageSize).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
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
                  labelText: 'ابحث بالكود أو اسم المُحيل/المدعو',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  _Chip(
                    label: 'كل الحالات',
                    selected: _status == null,
                    onTap: () => setState(() {
                      _status = null;
                      _page = 0;
                    }),
                  ),
                  for (final s in ReferralStatus.values)
                    if (s != ReferralStatus.unknown)
                      _Chip(
                        label: referralStatusLabel(s),
                        selected: _status == s,
                        onTap: () => setState(() {
                          _status = s;
                          _page = 0;
                        }),
                      ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Chip(
                    label: 'كل المكافآت',
                    selected: _rewardStatus == null,
                    onTap: () => setState(() => _rewardStatus = null),
                  ),
                  _Chip(
                    label: 'ممنوحة',
                    selected: _rewardStatus == 'granted',
                    onTap: () => setState(() => _rewardStatus = 'granted'),
                  ),
                  _Chip(
                    label: 'قيد الانتظار',
                    selected: _rewardStatus == 'pending',
                    onTap: () => setState(() => _rewardStatus = 'pending'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range_rounded, size: 18),
                    label: Text(
                      _range == null
                          ? 'نطاق التاريخ'
                          : '${referralArDate(_range!.start)} - ${referralArDate(_range!.end)}',
                    ),
                  ),
                  if (_range != null)
                    TextButton(
                      onPressed: () => setState(() => _range = null),
                      child: const Text('مسح التاريخ'),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        if (filtered.isEmpty)
          const AppCard(child: Center(child: Text('لا توجد إحالات مطابقة.')))
        else
          OpsDataTable(
            columns: const [
              OpsColumn('الكود', flex: 2, minWidth: 110),
              OpsColumn('المُحيل', flex: 2, minWidth: 110),
              OpsColumn('المدعو', flex: 2, minWidth: 110),
              OpsColumn('الحالة', flex: 2, minWidth: 130),
              OpsColumn('المكافأة', flex: 1, numeric: true, minWidth: 80),
              OpsColumn('حالة المكافأة', flex: 2, minWidth: 110),
              OpsColumn('التاريخ', flex: 2, minWidth: 110),
              OpsColumn('', flex: 1, minWidth: 56),
            ],
            rows: [for (final r in pageItems) _row(context, r)],
            total: filtered.length,
            currentPage: _page,
            pageSize: _pageSize,
            onPageChanged: (p) => setState(() => _page = p),
          ),
      ],
    );
  }

  List<Widget> _row(BuildContext context, ReferralRecord r) {
    return [
      Text(r.code, maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(r.referrerName, maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(r.referredName, maxLines: 1, overflow: TextOverflow.ellipsis),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: ReferralStatusChip(status: r.status),
      ),
      Text(referralArNum(r.rewardValue)),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: ReferralRewardStatusChip(status: r.rewardStatus),
      ),
      Text(referralArDate(r.createdAt)),
      IconButton(
        tooltip: 'تفاصيل',
        icon: const Icon(Icons.visibility_outlined, size: 18),
        onPressed: () => _showDetails(context, r),
      ),
    ];
  }

  void _showDetails(BuildContext context, ReferralRecord r) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل الإحالة'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Detail('رقم الإحالة', r.id),
              _Detail('كود الإحالة', r.code),
              _Detail('المُحيل', r.referrerName),
              _Detail('المدعو', r.referredName),
              _Detail('الحالة', referralStatusLabel(r.status)),
              _Detail('نوع المكافأة', referralRewardTypeLabel(r.rewardType)),
              _Detail('قيمة المكافأة', referralArNum(r.rewardValue)),
              _Detail('حالة المكافأة', r.rewardStatus),
              _Detail('رقم أول طلب', r.firstOrderId ?? '—'),
              _Detail('تاريخ الإنشاء', referralArDate(r.createdAt)),
              _Detail('تاريخ أول طلب', referralArDate(r.firstOrderAt)),
              _Detail('تاريخ منح المكافأة', referralArDate(r.rewardedAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
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
