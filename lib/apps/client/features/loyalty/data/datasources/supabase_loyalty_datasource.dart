import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/loyalty_account_model.dart';
import '../models/loyalty_reward_model.dart';
import '../models/loyalty_snapshot_model.dart';
import '../models/loyalty_tier_model.dart';
import '../models/points_transaction_model.dart';
import 'loyalty_datasource.dart';

class SupabaseLoyaltyDatasource implements LoyaltyDatasource {
  const SupabaseLoyaltyDatasource(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<LoyaltySnapshotModel> fetchSnapshot() async {
    final clientId = _requireClientId();

    final account = await _supabase
        .from('loyalty_accounts')
        .select()
        .eq('client_id', clientId)
        .maybeSingle();

    final results = await Future.wait([
      _optionalRows(
        () => _supabase
            .from('loyalty_transactions')
            .select()
            .eq('client_id', clientId)
            .order('created_at', ascending: false),
      ),
      _optionalRows(
        () => _supabase
            .from('loyalty_tiers')
            .select()
            .order('points_required_val', ascending: true),
      ),
      _optionalRows(
        () => _supabase
            .from('loyalty_rewards')
            .select()
            .eq('is_active', true)
            .order('points_cost', ascending: true),
      ),
    ]);

    return LoyaltySnapshotModel(
      account: LoyaltyAccountModel.fromJson(account),
      transactions: results[0].map(PointsTransactionModel.fromJson).toList(),
      tiers: results[1].map(LoyaltyTierModel.fromJson).toList(),
      rewards: results[2].map(LoyaltyRewardModel.fromJson).toList(),
    );
  }

  @override
  Future<void> redeemReward({
    required String rewardTitle,
    required int pointsCost,
  }) async {
    final clientId = _requireClientId();

    final account = await _supabase
        .from('loyalty_accounts')
        .select('points')
        .eq('client_id', clientId)
        .maybeSingle();

    final balance = account?['points'] as int? ?? 0;
    if (balance < pointsCost) {
      throw Exception('Insufficient points balance to redeem this reward');
    }

    final debited = await _supabase
        .from('loyalty_accounts')
        .update({'points': balance - pointsCost})
        .eq('client_id', clientId)
        .eq('points', balance)
        .select();

    if (debited.isEmpty) {
      throw Exception('Your points balance changed. Please try again.');
    }

    await _supabase.from('loyalty_transactions').insert({
      'client_id': clientId,
      'title': 'Redeemed: $rewardTitle',
      'points': -pointsCost,
      'is_earned': false,
    });
  }

  String _requireClientId() {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User is not authenticated');
    return user.id;
  }

  /// Runs [query], treating a missing table (PGRST205) as an empty result.
  Future<List<Map<String, dynamic>>> _optionalRows(
    Future<dynamic> Function() query,
  ) async {
    try {
      final result = await query();
      if (result is! List) return const <Map<String, dynamic>>[];
      return result.cast<Map<String, dynamic>>();
    } on PostgrestException {
      return const <Map<String, dynamic>>[];
    }
  }
}
