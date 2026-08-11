import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';

import '../../domain/entities/referral_leaderboard_item.dart';
import 'referral_format.dart';

enum _LbSort { completed, total, rewards }

class ReferralLeaderboardTab extends StatefulWidget {
  const ReferralLeaderboardTab({super.key, required this.items});

  final List<ReferralLeaderboardItem> items;

  @override
  State<ReferralLeaderboardTab> createState() => _ReferralLeaderboardTabState();
}

class _ReferralLeaderboardTabState extends State<ReferralLeaderboardTab> {
  String _query = '';
  _LbSort _sort = _LbSort.completed;
  int _page = 0;
  static const _pageSize = 10;

  List<ReferralLeaderboardItem> get _filtered {
    final q = _query.trim();
    final list =
        widget.items.where((i) {
          if (q.isEmpty) return true;
          return i.name.contains(q) ||
              i.code.contains(q.toUpperCase()) ||
              i.phone.contains(q);
        }).toList()..sort(
          (a, b) => switch (_sort) {
            _LbSort.completed => b.completedReferrals.compareTo(
              a.completedReferrals,
            ),
            _LbSort.total => b.totalReferrals.compareTo(a.totalReferrals),
            _LbSort.rewards => b.rewardsEarned.compareTo(a.rewardsEarned),
          },
        );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final isWide = MediaQuery.sizeOf(context).width >= 880;

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
                  labelText: 'ابحث بالاسم أو الكود أو الهاتف',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  _SortChip(
                    label: 'الأكثر إحالات مكتملة',
                    selected: _sort == _LbSort.completed,
                    onTap: () => setState(() => _sort = _LbSort.completed),
                  ),
                  _SortChip(
                    label: 'إجمالي الإحالات',
                    selected: _sort == _LbSort.total,
                    onTap: () => setState(() => _sort = _LbSort.total),
                  ),
                  _SortChip(
                    label: 'الأعلى مكافآت',
                    selected: _sort == _LbSort.rewards,
                    onTap: () => setState(() => _sort = _LbSort.rewards),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        if (filtered.isEmpty)
          const AppCard(child: Center(child: Text('لا يوجد مُحيلون بعد.')))
        else if (isWide)
          _buildTable(filtered)
        else
          ...filtered.asMap().entries.map(
            (e) => _LeaderboardCard(rank: e.key + 1, item: e.value),
          ),
      ],
    );
  }

  Widget _buildTable(List<ReferralLeaderboardItem> filtered) {
    final start = _page * _pageSize;
    final pageItems = filtered.skip(start).take(_pageSize).toList();
    return OpsDataTable(
      columns: const [
        OpsColumn('المرتبة', flex: 1, minWidth: 64),
        OpsColumn('العميل', flex: 2, minWidth: 120),
        OpsColumn('الهاتف', flex: 2, minWidth: 110),
        OpsColumn('الكود', flex: 2, minWidth: 110),
        OpsColumn('إجمالي', flex: 1, numeric: true, minWidth: 70),
        OpsColumn('مكتملة', flex: 1, numeric: true, minWidth: 70),
        OpsColumn('قيد الانتظار', flex: 1, numeric: true, minWidth: 90),
        OpsColumn('المكافآت', flex: 1, numeric: true, minWidth: 90),
        OpsColumn('آخر إحالة', flex: 2, minWidth: 110),
      ],
      rows: [
        for (var i = 0; i < pageItems.length; i++)
          _row(start + i + 1, pageItems[i]),
      ],
      total: filtered.length,
      currentPage: _page,
      pageSize: _pageSize,
      onPageChanged: (p) => setState(() => _page = p),
    );
  }

  List<Widget> _row(int rank, ReferralLeaderboardItem item) {
    return [
      _RankBadge(rank: rank),
      Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(
        item.phone.isEmpty ? '—' : referralArDigits(item.phone),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(item.code.isEmpty ? '—' : item.code),
      Text(referralArNum(item.totalReferrals)),
      Text(referralArNum(item.completedReferrals)),
      Text(referralArNum(item.pendingReferrals)),
      Text(referralArNum(item.rewardsEarned)),
      Text(referralArDate(item.lastReferralAt)),
    ];
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    
    final medal = switch (rank) {
      1 => const Color(0xFFD4AF37), 
      2 => const Color(0xFF9CA3AF), 
      3 => const Color(0xFFB45309), 
      _ => Theme.of(context).colorScheme.surfaceContainerHighest,
    };
    final isMedal = rank <= 3;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: medal, shape: BoxShape.circle),
      child: isMedal
          ? const Icon(
              Icons.emoji_events_rounded,
              size: 16,
              color: Colors.white,
            )
          : Text(referralArNum(rank), style: const TextStyle(fontSize: 12)),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
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

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.rank, required this.item});

  final int rank;
  final ReferralLeaderboardItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _RankBadge(rank: rank),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (item.code.isNotEmpty)
                        Text(
                          item.code,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                Text(
                  referralArNum(item.rewardsEarned),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.large),
            Wrap(
              spacing: AppSpacing.large,
              runSpacing: AppSpacing.small,
              children: [
                _Mini(
                  label: 'إجمالي',
                  value: referralArNum(item.totalReferrals),
                ),
                _Mini(
                  label: 'مكتملة',
                  value: referralArNum(item.completedReferrals),
                ),
                _Mini(
                  label: 'قيد الانتظار',
                  value: referralArNum(item.pendingReferrals),
                ),
                _Mini(
                  label: 'آخر إحالة',
                  value: referralArDate(item.lastReferralAt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
