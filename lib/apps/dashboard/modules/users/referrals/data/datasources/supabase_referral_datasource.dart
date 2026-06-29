import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/referral_analytics.dart';
import '../../domain/entities/referral_leaderboard_item.dart';
import '../../domain/entities/referral_record.dart';
import '../../domain/entities/referral_reward_config.dart';
import '../../domain/entities/referral_reward_transaction.dart';
import 'referral_datasource.dart';

/// Real Supabase-backed datasource for the referral admin module. Reads the
/// schema from `supabase/migrations/20260620090000_referral_system.sql`. All
/// reads degrade to empty when a relation is not yet provisioned so the screen
/// stays usable before the migration is applied.
class SupabaseReferralDatasource implements ReferralDatasource {
  const SupabaseReferralDatasource(this._client);

  final SupabaseClient _client;

  bool _isMissingRelation(Object error) =>
      error is PostgrestException &&
      (error.code == '42P01' ||
          error.code == 'PGRST205' ||
          error.code == '42703');

  // ── Config ────────────────────────────────────────────────────────────────
  @override
  Future<ReferralRewardConfig> getRewardConfig() async {
    try {
      final row = await _client
          .from('referral_rewards')
          .select()
          .eq('id', 1)
          .maybeSingle();
      return _mapConfig(row);
    } catch (error) {
      if (_isMissingRelation(error)) return _defaultConfig();
      rethrow;
    }
  }

  @override
  Future<ReferralRewardConfig> updateRewardConfig(
    ReferralRewardConfig config,
  ) async {
    final row = await _client
        .from('referral_rewards')
        .upsert({
          'id': 1,
          'enabled': config.enabled,
          'reward_type': config.rewardType,
          'reward_value': config.rewardValue,
          'referred_value': config.referredValue,
          'currency': config.currency,
          'coupon_code': config.couponCode,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .maybeSingle();
    return _mapConfig(row);
  }

  // ── Analytics ───────────────────────────────────────────────────────────────
  @override
  Future<ReferralAnalytics> getAnalytics() async {
    try {
      final view = await _client
          .from('referral_analytics')
          .select()
          .maybeSingle();
      final totalCodes = await _client.from('referral_codes').count();

      final statusRows = await _client.from('referrals').select('status');
      var pending = 0, firstOrder = 0, granted = 0;
      for (final r in statusRows) {
        final status = ReferralStatus.fromDb(r['status']?.toString());
        if (status == ReferralStatus.rewardGranted) {
          granted++;
        } else if (status == ReferralStatus.firstOrderCompleted) {
          firstOrder++;
        } else if (status.isPending) {
          pending++;
        }
      }

      final txRows = await _client
          .from('referral_reward_transactions')
          .select('role, reward_value');
      var referrerRewards = 0.0, referredRewards = 0.0;
      for (final t in txRows) {
        final value = _toDouble(t['reward_value']);
        if (t['role']?.toString() == 'referred') {
          referredRewards += value;
        } else {
          referrerRewards += value;
        }
      }

      final total = _toInt(view?['total_referrals']);
      final successful = _toInt(view?['successful_referrals']);
      return ReferralAnalytics(
        totalCodes: totalCodes,
        totalReferrals: total,
        pendingReferrals: pending,
        firstOrderCompleted: firstOrder,
        rewardGranted: granted,
        conversionRate: _toDouble(view?['conversion_rate']) == 0 && total > 0
            ? (successful / total) * 100
            : _toDouble(view?['conversion_rate']),
        referrerRewards: referrerRewards,
        referredRewards: referredRewards,
        totalRewards: referrerRewards + referredRewards,
      );
    } catch (error) {
      if (_isMissingRelation(error)) return ReferralAnalytics.empty;
      rethrow;
    }
  }

  // ── Leaderboard ─────────────────────────────────────────────────────────────
  @override
  Future<List<ReferralLeaderboardItem>> getLeaderboard() async {
    try {
      final viewRows = await _client
          .from('referral_leaderboard')
          .select()
          .limit(50);
      if (viewRows.isEmpty) return const [];

      final ids = viewRows
          .map((r) => r['referrer_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      // Per-referrer aggregates (total / pending / last referral date).
      final agg = <String, _ReferrerAgg>{};
      final aggRows = await _client
          .from('referrals')
          .select('referrer_id, status, created_at');
      for (final r in aggRows) {
        final id = r['referrer_id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final entry = agg.putIfAbsent(id, _ReferrerAgg.new);
        entry.total++;
        if (ReferralStatus.fromDb(r['status']?.toString()).isPending) {
          entry.pending++;
        }
        final created = _parseDate(r['created_at']);
        if (created != null &&
            (entry.last == null || created.isAfter(entry.last!))) {
          entry.last = created;
        }
      }

      final phones = await _batchLookup('clients', 'id', ids, 'phone');
      final codes = await _batchLookup(
        'referral_codes',
        'user_id',
        ids,
        'code',
      );

      var rank = 1;
      return [
        for (final row in viewRows)
          () {
            final id = row['referrer_id']?.toString() ?? '';
            final a = agg[id] ?? _ReferrerAgg();
            return ReferralLeaderboardItem(
              rank: rank++,
              referrerId: id,
              name: row['name']?.toString() ?? 'عضو',
              phone: phones[id] ?? '',
              code: codes[id] ?? '',
              totalReferrals: a.total,
              completedReferrals: _toInt(row['successful_count']),
              pendingReferrals: a.pending,
              rewardsEarned: _toDouble(row['total_rewards']),
              lastReferralAt: a.last,
            );
          }(),
      ];
    } catch (error) {
      if (_isMissingRelation(error)) return const [];
      rethrow;
    }
  }

  // ── History ─────────────────────────────────────────────────────────────────
  @override
  Future<List<ReferralRecord>> getHistory() async {
    try {
      final rows = await _client
          .from('referrals')
          .select(
            'id, referral_code, referrer_id, referred_id, referred_name, '
            'status, reward_type, reward_value, reward_status, first_order_id, '
            'created_at, first_order_at, rewarded_at',
          )
          .order('created_at', ascending: false)
          .limit(1000);

      final ids = <String>{
        for (final r in rows) ...[
          r['referrer_id']?.toString() ?? '',
          r['referred_id']?.toString() ?? '',
        ],
      }..removeWhere((id) => id.isEmpty);
      final names = await _batchLookup(
        'clients',
        'id',
        ids.toList(),
        'full_name',
      );

      return [
        for (final r in rows)
          ReferralRecord(
            id: r['id']?.toString() ?? '',
            code: r['referral_code']?.toString() ?? '',
            referrerId: r['referrer_id']?.toString() ?? '',
            referrerName: names[r['referrer_id']?.toString()] ?? '—',
            referredId: r['referred_id']?.toString() ?? '',
            referredName:
                r['referred_name']?.toString() ??
                names[r['referred_id']?.toString()] ??
                '—',
            status: ReferralStatus.fromDb(r['status']?.toString()),
            rewardType: r['reward_type']?.toString() ?? '',
            rewardValue: _toDouble(r['reward_value']),
            rewardStatus: r['reward_status']?.toString() ?? 'pending',
            firstOrderId: r['first_order_id']?.toString(),
            createdAt: _parseDate(r['created_at']) ?? DateTime.now(),
            firstOrderAt: _parseDate(r['first_order_at']),
            rewardedAt: _parseDate(r['rewarded_at']),
          ),
      ];
    } catch (error) {
      if (_isMissingRelation(error)) return const [];
      rethrow;
    }
  }

  // ── Reward transactions (immutable ledger) ──────────────────────────────────
  @override
  Future<List<ReferralRewardTransaction>> getRewardTransactions() async {
    try {
      final rows = await _client
          .from('referral_reward_transactions')
          .select(
            'id, referral_id, user_id, role, reward_type, reward_value, '
            'status, created_at',
          )
          .order('created_at', ascending: false)
          .limit(1000);

      final ids = rows
          .map((r) => r['user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      final names = await _batchLookup('clients', 'id', ids, 'full_name');

      return [
        for (final r in rows)
          ReferralRewardTransaction(
            id: r['id']?.toString() ?? '',
            referralId: r['referral_id']?.toString() ?? '',
            userId: r['user_id']?.toString() ?? '',
            userName: names[r['user_id']?.toString()] ?? '—',
            role: r['role']?.toString() ?? '',
            rewardType: r['reward_type']?.toString() ?? '',
            rewardValue: _toDouble(r['reward_value']),
            status: r['status']?.toString() ?? '',
            createdAt: _parseDate(r['created_at']) ?? DateTime.now(),
          ),
      ];
    } catch (error) {
      if (_isMissingRelation(error)) return const [];
      rethrow;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Future<Map<String, String>> _batchLookup(
    String table,
    String keyColumn,
    List<String> ids,
    String valueColumn,
  ) async {
    if (ids.isEmpty) return const {};
    final rows = await _client
        .from(table)
        .select('$keyColumn, $valueColumn')
        .inFilter(keyColumn, ids);
    return {
      for (final r in rows)
        if (r[keyColumn] != null)
          r[keyColumn].toString(): r[valueColumn]?.toString() ?? '',
    };
  }

  ReferralRewardConfig _mapConfig(Map<String, dynamic>? row) {
    if (row == null) return _defaultConfig();
    return ReferralRewardConfig(
      enabled: row['enabled'] as bool? ?? true,
      rewardType: row['reward_type']?.toString() ?? 'wallet',
      rewardValue: _toDouble(row['reward_value']),
      referredValue: _toDouble(row['referred_value']),
      currency: row['currency']?.toString() ?? 'EGP',
      couponCode: row['coupon_code']?.toString(),
      updatedAt: _parseDate(row['updated_at']),
    );
  }

  ReferralRewardConfig _defaultConfig() => const ReferralRewardConfig(
    enabled: true,
    rewardType: 'wallet',
    rewardValue: 50,
    referredValue: 25,
    currency: 'EGP',
  );

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}

class _ReferrerAgg {
  int total = 0;
  int pending = 0;
  DateTime? last;
}
