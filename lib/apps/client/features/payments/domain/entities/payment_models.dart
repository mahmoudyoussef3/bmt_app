enum PaymentMethodType {
  creditCard,
  vodafoneCash,
  instapay,
  walletBalance,
  cashOnBoarding,
}

class PaymentMethodData {
  final PaymentMethodType type;
  final String title;
  final String subtitle;
  final bool recommended;

  const PaymentMethodData({
    required this.type,
    required this.title,
    required this.subtitle,
    this.recommended = false,
  });
}

class PaymentCheckoutData {
  final String tripId;
  final String pickupPoint;
  final String destination;
  final String vehicleNumber;
  final String tripDate;
  final String departureTime;
  final String arrivalTime;
  final String selectedSeatId;
  final String selectedSeat;
  final String driverName;
  final int baseFare;
  final int serviceFee;
  final int tax;
  final String walletBalanceLabel;
  final int walletBalance;

  const PaymentCheckoutData({
    required this.tripId,
    required this.pickupPoint,
    required this.destination,
    required this.vehicleNumber,
    required this.tripDate,
    required this.departureTime,
    required this.arrivalTime,
    required this.selectedSeatId,
    required this.selectedSeat,
    required this.driverName,
    this.baseFare = 60,
    this.serviceFee = 5,
    this.tax = 3,
    this.walletBalanceLabel = 'Wallet Balance',
    this.walletBalance = 250,
  });

  int get subtotal => baseFare + serviceFee + tax;

  int totalForDiscount(int promoDiscount) =>
      (subtotal - promoDiscount).clamp(0, subtotal);

  int remainingWalletAfterPayment(int total) =>
      (walletBalance - total).clamp(0, walletBalance);

  String get route => '$pickupPoint → $destination';
}

class PaymentResultData {
  final String transactionId;
  final String bookingReference;
  final int paidAmount;
  final String paymentMethodTitle;
  final String? promoCode;
  final int promoDiscount;
  final bool fromWallet;
  final int? remainingWalletBalance;

  const PaymentResultData({
    required this.transactionId,
    required this.bookingReference,
    required this.paidAmount,
    required this.paymentMethodTitle,
    required this.promoCode,
    required this.promoDiscount,
    required this.fromWallet,
    required this.remainingWalletBalance,
  });
}
