import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/payment_models.dart';
import 'payment_datasource.dart';

class SupabasePaymentDatasource implements PaymentDatasource {
  const SupabasePaymentDatasource(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<List<PaymentMethodData>> getPaymentMethods() async {
    try {
      final response = await _supabase
          .from('payment_methods')
          .select()
          .eq('is_active', true);

      final methods = response
          .map((json) => _mapPaymentMethod(Map<String, dynamic>.from(json)))
          .whereType<PaymentMethodData>()
          .toList();

      return methods;
    } on PostgrestException catch (error) {
      throw Exception(
        error.message.isEmpty
            ? 'Unable to load payment methods.'
            : error.message,
      );
    }
  }

  PaymentMethodData? _mapPaymentMethod(Map<String, dynamic> json) {
    final type = _parseType(
      json['type']?.toString() ??
          json['method_type']?.toString() ??
          json['code']?.toString() ??
          '',
    );
    if (type == null) return null;

    return PaymentMethodData(
      type: type,
      title:
          json['title']?.toString() ??
          json['name']?.toString() ??
          _defaultTitle(type),
      subtitle:
          json['subtitle']?.toString() ??
          json['description']?.toString() ??
          _defaultSubtitle(type),
      recommended:
          json['recommended'] == true || json['is_recommended'] == true,
    );
  }

  PaymentMethodType? _parseType(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    return switch (normalized) {
      'credit_card' ||
      'card' ||
      'visa' ||
      'mastercard' => PaymentMethodType.creditCard,
      'instapay' || 'insta_pay' => PaymentMethodType.instapay,
      'vodafone_cash' ||
      'mobile_wallet' ||
      'wallet_transfer' => PaymentMethodType.vodafoneCash,
      'wallet_balance' ||
      'user_balance' ||
      'balance' => PaymentMethodType.walletBalance,
      'cash_on_boarding' ||
      'cash' ||
      'cash_with_driver' => PaymentMethodType.cashOnBoarding,
      _ => null,
    };
  }

  String _defaultTitle(PaymentMethodType type) {
    return switch (type) {
      PaymentMethodType.creditCard => 'Card',
      PaymentMethodType.instapay => 'InstaPay',
      PaymentMethodType.vodafoneCash => 'Mobile wallet',
      PaymentMethodType.cashOnBoarding => 'Cash with driver',
      PaymentMethodType.walletBalance => 'Wallet balance',
    };
  }

  String _defaultSubtitle(PaymentMethodType type) {
    return switch (type) {
      PaymentMethodType.creditCard => 'Pay securely by card',
      PaymentMethodType.instapay => 'Transfer and attach the receipt',
      PaymentMethodType.vodafoneCash => 'Transfer from a mobile wallet',
      PaymentMethodType.cashOnBoarding => 'Pay when boarding',
      PaymentMethodType.walletBalance => 'Use your available app balance',
    };
  }
}
