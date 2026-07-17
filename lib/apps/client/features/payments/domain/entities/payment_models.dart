enum PaymentMethodType {
  creditCard,
  vodafoneCash,
  instapay,
  bankTransfer,
  walletBalance,
}

class PaymentMethodData {
  final PaymentMethodType type;
  final String title;
  final String subtitle;
  final bool recommended;
  final String? transferAccount;
  final String? accountHolder;
  final String? gateway;
  final String? integrationId;
  final String? iframeId;
  final List<String> supportedChannels;
  final String? instructions;

  const PaymentMethodData({
    required this.type,
    required this.title,
    required this.subtitle,
    this.recommended = false,
    this.transferAccount,
    this.accountHolder,
    this.gateway,
    this.integrationId,
    this.iframeId,
    this.supportedChannels = const [],
    this.instructions,
  });
}

class PaymentCheckoutData {
  final String tripId;
  final String pickupPoint;
  final String destination;
  final String vehicleNumber;
  final String vehicleName;
  final String vehicleImageUrl;
  final String tripDate;
  final String departureTime;
  final String arrivalTime;
  final String selectedSeatId;
  final String selectedSeat;
  final String driverName;
  final String driverImageUrl;
  final double driverRating;
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
    this.vehicleName = '',
    this.vehicleImageUrl = '',
    this.driverImageUrl = '',
    this.driverRating = 0,
    this.baseFare = 0,
    this.serviceFee = 0,
    this.tax = 0,
    this.walletBalanceLabel = 'Wallet Balance',
    this.walletBalance = 0,
  });

  /// Rebuilds checkout data from untyped route arguments, mirroring the
  /// `BookingSearchQuery.fromArguments` convention. Every field falls back to
  /// an empty value so a malformed hand-off renders a blank ticket rather than
  /// throwing during a route build.
  static PaymentCheckoutData fromArguments(Object? args) {
    if (args is PaymentCheckoutData) return args;
    if (args is! Map) {
      return const PaymentCheckoutData(
        tripId: '',
        pickupPoint: '',
        destination: '',
        vehicleNumber: '',
        tripDate: '',
        departureTime: '',
        arrivalTime: '',
        selectedSeatId: '',
        selectedSeat: '',
        driverName: '',
      );
    }
    return PaymentCheckoutData(
      tripId: args['tripId']?.toString() ?? '',
      pickupPoint: args['pickupPoint']?.toString() ?? '',
      destination: args['destination']?.toString() ?? '',
      vehicleNumber: args['vehicleNumber']?.toString() ?? '',
      tripDate: args['tripDate']?.toString() ?? '',
      departureTime: args['departureTime']?.toString() ?? '',
      arrivalTime: args['arrivalTime']?.toString() ?? '',
      selectedSeatId: args['selectedSeatId']?.toString() ?? '',
      selectedSeat: args['selectedSeat']?.toString() ?? '',
      driverName: args['driverName']?.toString() ?? '',
      vehicleName: args['vehicleName']?.toString() ?? '',
      vehicleImageUrl: args['vehicleImageUrl']?.toString() ?? '',
      driverImageUrl: args['driverImageUrl']?.toString() ?? '',
      driverRating: _toDouble(args['driverRating']),
      baseFare: _toMoney(args['baseFare']),
      serviceFee: _toMoney(args['serviceFee']),
      tax: _toMoney(args['tax']),
    );
  }

  /// Fares cross the route boundary as either a num or its string form.
  static int _toMoney(Object? value) {
    if (value is num) return value.round();
    return num.tryParse(value?.toString() ?? '')?.round() ?? 0;
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// The friendly label for the vehicle on the ticket: its name (brand/model)
  /// when known, falling back to the plate/code so the fact is never blank.
  String get vehicleLabel =>
      vehicleName.trim().isNotEmpty ? vehicleName.trim() : vehicleNumber;

  int get subtotal => baseFare + serviceFee + tax;

  int totalForDiscount(int promoDiscount) =>
      (subtotal - promoDiscount).clamp(0, subtotal);

  int remainingWalletAfterPayment(int total) =>
      (walletBalance - total).clamp(0, walletBalance);

  String get route => '$pickupPoint → $destination';

  List<String> get missingRequiredFields {
    final missing = <String>[];
    if (tripId.trim().isEmpty) missing.add('Trip');
    if (pickupPoint.trim().isEmpty || destination.trim().isEmpty) {
      missing.add('Route');
    }
    if (vehicleNumber.trim().isEmpty) missing.add('Vehicle');
    if (selectedSeatId.trim().isEmpty || selectedSeat.trim().isEmpty) {
      missing.add('Seat');
    }
    if (departureTime.trim().isEmpty) missing.add('Departure');
    if (arrivalTime.trim().isEmpty) missing.add('Arrival');
    if (baseFare <= 0) missing.add('Price');
    return missing;
  }

  bool get isReadyForPayment => missingRequiredFields.isEmpty;
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

class CardPaymentSession {
  const CardPaymentSession({
    required this.checkoutUrl,
    required this.gatewayReference,
  });

  final String checkoutUrl;
  final String gatewayReference;
}
