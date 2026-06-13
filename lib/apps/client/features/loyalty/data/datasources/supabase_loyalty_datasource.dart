import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/loyalty_data.dart';
import 'loyalty_datasource.dart';

class SupabaseLoyaltyDatasource implements LoyaltyDatasource {
  final SupabaseClient _supabase;

  const SupabaseLoyaltyDatasource(this._supabase);

  String _calculateTier(int points) {
    if (points >= 3000) return 'Platinum';
    if (points >= 2000) return 'Gold';
    if (points >= 1000) return 'Silver';
    return 'Bronze';
  }

  @override
  Future<LoyaltyData> getLoyaltyData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    // 1. Fetch points and wallet balance
    final accountResponse = await _supabase
        .from('loyalty_accounts')
        .select()
        .eq('client_id', user.id)
        .maybeSingle();

    final currentPoints = accountResponse?['points'] as int? ?? 0;
    // double walletBalance = double.tryParse(accountResponse?['wallet_balance']?.toString() ?? '0') ?? 0.0;

    // 2. Fetch point transactions
    final txResponse = await _supabase
        .from('loyalty_transactions')
        .select()
        .eq('client_id', user.id)
        .order('created_at', ascending: false);

    final transactions = txResponse.map((tx) {
      return PointsTransaction(
        title: tx['title']?.toString() ?? 'Transaction',
        date: tx['created_at'] != null ? tx['created_at'].toString().split('T')[0] : 'Unknown',
        points: tx['points'] as int? ?? 0,
        isEarned: tx['is_earned'] as bool? ?? true,
      );
    }).toList();

    return LoyaltyData(
      currentPoints: currentPoints,
      currentTierName: _calculateTier(currentPoints),
      tiers: const [
        LoyaltyTier(
          name: 'Bronze',
          pointsRequired: '0 pts',
          iconKey: 'premium',
          gradientColors: [0xFF8C5A3C, 0xFF5C3A21],
          perks: [
            'Earn 1x points on standard commutes',
            'Standard customer support ticket queues',
          ],
        ),
        LoyaltyTier(
          name: 'Silver',
          pointsRequired: '1,000 pts',
          iconKey: 'shield',
          gradientColors: [0xFFB0BEC5, 0xFF607D8B],
          perks: [
            'Earn 1.2x points on comfort rides',
            'Priority seating allocations',
            'Dedicated Silver support queue hotline',
          ],
        ),
        LoyaltyTier(
          name: 'Gold',
          pointsRequired: '2,000 pts',
          iconKey: 'stars',
          gradientColors: [0xFFFFD54F, 0xFFFFB300],
          perks: [
            'Earn 1.5x points on luxury coaches',
            'Free shuttle scheduling adjustments',
            'VIP boarding privileges',
            'No service fees on refund transactions',
          ],
        ),
        LoyaltyTier(
          name: 'Platinum',
          pointsRequired: '3,000 pts',
          iconKey: 'diamond',
          gradientColors: [0xFFE2E8F0, 0xFF475569],
          perks: [
            'Earn 2x points on all shuttle rides',
            'Complimentary cabin beverage selection',
            'Guaranteed reserved seat on commute lines',
            'Priority executive ticket desk helpline',
            'Free trip voucher every 15 rides',
          ],
        ),
      ],
      transactions: transactions,
      rewards: const [
        RedeemableReward(
          id: 'r1',
          title: 'EGP 30 Off Shuttle Ride',
          description: 'Get EGP 30 off standard or comfort daily runs.',
          pointsCost: 300,
          valueLabel: 'EGP 30',
          category: 'Discount',
          couponCode: 'DISC30PTS',
        ),
        RedeemableReward(
          id: 'r2',
          title: 'EGP 60 Off Commute',
          description: 'Save EGP 60 on your next booking seat fare.',
          pointsCost: 500,
          valueLabel: 'EGP 60',
          category: 'Discount',
          couponCode: 'DISC60PTS',
        ),
        RedeemableReward(
          id: 'r3',
          title: '1 Free Commute Ticket',
          description: 'Free single ride voucher valid on any shuttle coach.',
          pointsCost: 1000,
          valueLabel: 'FREE TRIP',
          category: 'FreeRide',
          couponCode: 'FREETRIPPTS',
        ),
        RedeemableReward(
          id: 'r4',
          title: 'EGP 100 Cashback',
          description: 'Claim EGP 100 directly to your main BMT account wallet.',
          pointsCost: 1500,
          valueLabel: 'EGP 100 CASH',
          category: 'Cashback',
          couponCode: 'CASHBACK100',
        ),
        RedeemableReward(
          id: 'r5',
          title: 'EGP 200 Package Discount',
          description: 'Get EGP 200 off your next weekly/monthly subscription bundle.',
          pointsCost: 2000,
          valueLabel: 'EGP 200 OFF',
          category: 'Package',
          couponCode: 'PKGDIST200',
        ),
        RedeemableReward(
          id: 'r6',
          title: 'Free Month Upgrade',
          description: 'Upgrade your weekly package to VIP comfort tier package.',
          pointsCost: 2800,
          valueLabel: 'FREE UPGRADE',
          category: 'Package',
          couponCode: 'VIPUPGRADEFREE',
        ),
      ],
    );
  }
}
