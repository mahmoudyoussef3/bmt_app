import 'package:flutter/material.dart';

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
  final IconData icon;
  final bool recommended;

  const PaymentMethodData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.recommended = false,
  });
}

class PaymentCheckoutData {
  final String pickupPoint;
  final String destination;
  final String vehicleNumber;
  final String departureTime;
  final String arrivalTime;
  final String selectedSeat;
  final String driverName;
  final int baseFare;
  final int serviceFee;
  final int tax;
  final String walletBalanceLabel;
  final int walletBalance;

  const PaymentCheckoutData({
    required this.pickupPoint,
    required this.destination,
    required this.vehicleNumber,
    required this.departureTime,
    required this.arrivalTime,
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
