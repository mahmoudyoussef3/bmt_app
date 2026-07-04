import 'dart:typed_data';

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
          .eq('is_active', true)
          .order('sort_order');

      final methods = response
          .map((json) => _mapPaymentMethod(Map<String, dynamic>.from(json)))
          .whereType<PaymentMethodData>()
          .toList();

      return methods;
    } on PostgrestException catch (error) {
      // Table not yet provisioned — degrade to an empty list so the screen
      // shows its empty state instead of a crash.
      if (error.code == 'PGRST205' || error.code == '42P01') {
        return const <PaymentMethodData>[];
      }
      throw Exception(
        error.message.isEmpty
            ? 'Unable to load payment methods.'
            : error.message,
      );
    }
  }

  @override
  Future<int> validatePromoCode(String code) async {
    try {
      final normalized = code.trim().toUpperCase();
      if (normalized.isEmpty) return 0;

      final now = DateTime.now().toUtc().toIso8601String();
      final row = await _supabase
          .from('promo_codes')
          .select('discount_amount, discount_type, max_uses, use_count')
          .eq('code', normalized)
          .eq('is_active', true)
          .or('expires_at.is.null,expires_at.gt.$now')
          .maybeSingle();

      if (row == null) return 0;

      final maxUses = row['max_uses'] as int?;
      final useCount = row['use_count'] as int? ?? 0;
      if (maxUses != null && useCount >= maxUses) return 0;

      final discountAmount = (row['discount_amount'] as num?)?.toInt() ?? 0;
      final discountType = row['discount_type']?.toString() ?? 'fixed';

      // For 'percentage' type the caller is responsible for applying the %.
      // We return the raw value in both cases; the cubit already treats the
      // returned int as the discount to subtract from the total.
      return discountType == 'percentage' ? discountAmount : discountAmount;
    } on PostgrestException {
      return 0;
    }
  }

  @override
  Future<String> uploadReceipt({
    required String bookingOrTripId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath =
        '${user.id}/$bookingOrTripId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await _supabase.storage
        .from('payment-receipts')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    return _supabase.storage
        .from('payment-receipts')
        .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
  }

  @override
  Future<CardPaymentSession> createCardPaymentSession({
    required PaymentCheckoutData checkoutData,
    required PaymentMethodData paymentMethod,
    required String bookingId,
    required int amount,
  }) async {
    final user = _supabase.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    try {
      final response = await _supabase.functions.invoke(
        'paymob-create-intention',
        body: {
          'booking_id': bookingId,
          'amount': amount,
          'currency': 'EGP',
          'trip_id': checkoutData.tripId,
          'route': checkoutData.route,
          'seat': checkoutData.selectedSeat,
          'integration_id': paymentMethod.integrationId,
          'iframe_id': paymentMethod.iframeId,
          'customer': {
            'email': user?.email,
            'name':
                metadata['full_name']?.toString() ??
                metadata['name']?.toString(),
            'phone': metadata['phone']?.toString(),
          },
        },
      );
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final error = data['error']?.toString().trim();
      if (error != null && error.isNotEmpty) {
        throw Exception(error);
      }
      final checkoutUrl = data['checkout_url']?.toString() ?? '';
      if (checkoutUrl.isEmpty) {
        throw Exception('Paymob checkout URL was not returned.');
      }
      return CardPaymentSession(
        checkoutUrl: checkoutUrl,
        gatewayReference:
            data['gateway_reference']?.toString() ??
            data['order_id']?.toString() ??
            data['intention_id']?.toString() ??
            bookingId,
      );
    } on FunctionException catch (error) {
      throw Exception(_functionErrorMessage(error));
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
    final metadata = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : const <String, dynamic>{};
    final channels = metadata['supported_channels'] is List
        ? (metadata['supported_channels'] as List)
              .map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList()
        : const <String>[];

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
      transferAccount: metadata['transfer_account']?.toString(),
      accountHolder: metadata['account_holder']?.toString(),
      gateway: metadata['gateway']?.toString(),
      integrationId: metadata['integration_id']?.toString(),
      iframeId: metadata['iframe_id']?.toString(),
      supportedChannels: channels,
      instructions: metadata['instructions']?.toString(),
    );
  }

  String _functionErrorMessage(FunctionException error) {
    final details = error.details;
    if (details is Map) {
      final message =
          details['error'] ?? details['message'] ?? details['detail'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    final reason = error.reasonPhrase;
    if (reason != null && reason.trim().isNotEmpty) return reason;
    return 'Unable to create Paymob checkout session.';
  }

  PaymentMethodType? _parseType(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    return switch (normalized) {
      'credit_card' ||
      'card' ||
      'visa' ||
      'mastercard' => PaymentMethodType.creditCard,
      'instapay' || 'insta_pay' => PaymentMethodType.instapay,
      'bank_transfer' || 'bank' => PaymentMethodType.bankTransfer,
      'vodafone_cash' ||
      'mobile_wallet' ||
      'wallet_transfer' => PaymentMethodType.vodafoneCash,
      'wallet_balance' ||
      'user_balance' ||
      'balance' => PaymentMethodType.walletBalance,
      _ => null,
    };
  }

  String _defaultTitle(PaymentMethodType type) {
    return switch (type) {
      PaymentMethodType.creditCard => 'Card',
      PaymentMethodType.instapay => 'InstaPay',
      PaymentMethodType.bankTransfer => 'Bank transfer',
      PaymentMethodType.vodafoneCash => 'Mobile wallet',
      PaymentMethodType.walletBalance => 'Wallet balance',
    };
  }

  String _defaultSubtitle(PaymentMethodType type) {
    return switch (type) {
      PaymentMethodType.creditCard => 'Pay securely by card',
      PaymentMethodType.instapay => 'Transfer and attach the receipt',
      PaymentMethodType.bankTransfer =>
        'Transfer to the configured bank account',
      PaymentMethodType.vodafoneCash => 'Transfer from a mobile wallet',
      PaymentMethodType.walletBalance => 'Use your available app balance',
    };
  }
}
