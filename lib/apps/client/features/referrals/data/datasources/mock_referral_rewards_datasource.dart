import '../../domain/entities/referral_rewards.dart';

class MockReferralRewardsDatasource {
  const MockReferralRewardsDatasource();

  Future<ReferralRewardsData> getReferralRewardsData() async {
    return ReferralRewardsData(
      referralCode: 'MEGA-SHUTTLE-77X',
      totalInvites: 12,
      successfulReferrals: 5,
      earnedRewardsTotal: 250,
      walletBalance: 100,
      contacts: [
        MockContact(name: 'Ahmed Kamel', detail: '+20 100 123 4567'),
        MockContact(name: 'Sarah Aly', detail: 'sarah.aly@mail.com'),
        MockContact(name: 'Mostafa Ibrahim', detail: '+20 111 987 6543'),
        MockContact(name: 'Kareem Fahmy', detail: 'kareem.f@domain.com'),
        MockContact(name: 'Lobna Mansour', detail: '+20 122 456 7890'),
        MockContact(name: 'Yasser Gamal', detail: 'yasser.g@mail.net'),
      ],
      history: [
        ReferralHistoryItem(
          name: 'Sarah Aly',
          date: 'May 28, 2026',
          status: 'Completed',
          rewardAmount: 50,
        ),
        ReferralHistoryItem(
          name: 'Ahmed Kamel',
          date: 'May 24, 2026',
          status: 'Completed',
          rewardAmount: 50,
        ),
        ReferralHistoryItem(
          name: 'Hazem Soliman',
          date: 'May 20, 2026',
          status: 'Pending',
          rewardAmount: 50,
        ),
        ReferralHistoryItem(
          name: 'Mariam Fawzy',
          date: 'May 18, 2026',
          status: 'Expired',
          rewardAmount: 0,
        ),
        ReferralHistoryItem(
          name: 'Tarek Refaat',
          date: 'May 12, 2026',
          status: 'Completed',
          rewardAmount: 50,
        ),
        ReferralHistoryItem(
          name: 'Nour El-Din',
          date: 'May 08, 2026',
          status: 'Completed',
          rewardAmount: 50,
        ),
      ],
      vouchers: [
        ScratchVoucher(
          id: 'v1',
          title: 'Shuttle Commute Reward',
          description: 'Get EGP 50 off your next luxury coach trip.',
          promoCode: 'COMMUTE50',
          amount: 'EGP 50',
        ),
        ScratchVoucher(
          id: 'v2',
          title: 'Weekend Gateaway Discount',
          description: 'Get 30% off any route to Alexandria or Banha.',
          promoCode: 'WEEKEND30',
          amount: '30% OFF',
        ),
        ScratchVoucher(
          id: 'v3',
          title: 'Premium Class Upgrade',
          description:
              'Upgrade your standard seat to Premium Luxury standard at no extra cost.',
          promoCode: 'UPGRADEVIP',
          amount: 'VIP SEAT',
          isRevealed: true,
        ),
      ],
    );
  }
}
