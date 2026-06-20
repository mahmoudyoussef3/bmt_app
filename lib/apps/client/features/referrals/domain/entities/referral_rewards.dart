class ReferralContact {
  ReferralContact({
    required this.name,
    required this.detail,
    this.isInvited = false,
  });

  final String name;
  final String detail;
  bool isInvited;
}

class ReferralHistoryItem {
  ReferralHistoryItem({
    required this.name,
    required this.date,
    required this.status,
    required this.rewardAmount,
  });

  final String name;
  final String date;
  final String status;
  final int rewardAmount;
}

class ScratchVoucher {
  ScratchVoucher({
    required this.id,
    required this.title,
    required this.description,
    required this.promoCode,
    required this.amount,
    this.isRevealed = false,
  });

  final String id;
  final String title;
  final String description;
  final String promoCode;
  final String amount;
  bool isRevealed;
}

class ReferralRewardsData {
  ReferralRewardsData({
    required this.referralCode,
    required this.totalInvites,
    required this.successfulReferrals,
    required this.earnedRewardsTotal,
    required this.walletBalance,
    required this.contacts,
    required this.history,
    required this.vouchers,
  });

  final String referralCode;
  int totalInvites;
  final int successfulReferrals;
  int earnedRewardsTotal;
  int walletBalance;
  final List<ReferralContact> contacts;
  final List<ReferralHistoryItem> history;
  final List<ScratchVoucher> vouchers;
}
