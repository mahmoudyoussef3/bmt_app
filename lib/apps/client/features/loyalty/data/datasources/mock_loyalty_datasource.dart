import '../../domain/entities/loyalty_data.dart';

class MockLoyaltyDatasource {
  const MockLoyaltyDatasource();

  Future<LoyaltyData> getLoyaltyData() async {
    return const LoyaltyData(
      currentPoints: 2450,
      currentTierName: 'Gold',
      tiers: [
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
      transactions: [
        PointsTransaction(
          title: 'Trip to Smart Village (Luxury Coach)',
          date: 'Jun 2, 2026',
          points: 150,
          isEarned: true,
        ),
        PointsTransaction(
          title: 'Redeemed EGP 50 Trip Coupon',
          date: 'May 30, 2026',
          points: 500,
          isEarned: false,
        ),
        PointsTransaction(
          title: 'Trip to Banha Station (Comfort Van)',
          date: 'May 28, 2026',
          points: 120,
          isEarned: true,
        ),
        PointsTransaction(
          title: 'Welcome Points Bonus',
          date: 'May 24, 2026',
          points: 500,
          isEarned: true,
        ),
        PointsTransaction(
          title: 'Referral Bonus: Invited Ahmed',
          date: 'May 20, 2026',
          points: 300,
          isEarned: true,
        ),
        PointsTransaction(
          title: 'Loyalty Monthly Tier Boost',
          date: 'May 01, 2026',
          points: 200,
          isEarned: true,
          expirationDate: 'Jun 30, 2026',
        ),
      ],
      rewards: [
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
          description:
              'Claim EGP 100 directly to your main BMT account wallet.',
          pointsCost: 1500,
          valueLabel: 'EGP 100 CASH',
          category: 'Cashback',
          couponCode: 'CASHBACK100',
        ),
        RedeemableReward(
          id: 'r5',
          title: 'EGP 200 Package Discount',
          description:
              'Get EGP 200 off your next weekly/monthly subscription bundle.',
          pointsCost: 2000,
          valueLabel: 'EGP 200 OFF',
          category: 'Package',
          couponCode: 'PKGDIST200',
        ),
        RedeemableReward(
          id: 'r6',
          title: 'Free Month Upgrade',
          description:
              'Upgrade your weekly package to VIP comfort tier package.',
          pointsCost: 2800,
          valueLabel: 'FREE UPGRADE',
          category: 'Package',
          couponCode: 'VIPUPGRADEFREE',
        ),
      ],
    );
  }
}
