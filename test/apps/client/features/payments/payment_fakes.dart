import 'dart:typed_data';

import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/domain/repositories/payment_repository.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/apply_promo_code_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/get_payment_methods_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/cubit/payment_cubit.dart';

const cardMethod = PaymentMethodData(
  type: PaymentMethodType.creditCard,
  title: 'Card',
  subtitle: 'Visa or Mastercard',
  recommended: true,
);

const instapayMethod = PaymentMethodData(
  type: PaymentMethodType.instapay,
  title: 'InstaPay',
  subtitle: 'Transfer and upload a receipt',
);

const walletMethod = PaymentMethodData(
  type: PaymentMethodType.walletBalance,
  title: 'Wallet balance',
  subtitle: 'Pay from your BMT balance',
);

/// Supabase hands the client raw `HH:mm:ss` clocks and an ISO date — the
/// checkout is responsible for making those readable, so the fake keeps them
/// raw on purpose.
const sampleCheckout = PaymentCheckoutData(
  tripId: 'trip-1',
  pickupPoint: 'Nasr City',
  destination: 'Alexandria',
  vehicleNumber: 'BUS-114',
  tripDate: '2030-01-01',
  departureTime: '08:30:00',
  arrivalTime: '11:45:00',
  selectedSeatId: 'seat-1',
  selectedSeat: 'A3',
  driverName: 'Ahmed Samir',
  baseFare: 100,
  serviceFee: 10,
  walletBalance: 40,
);

/// Discounts are keyed by code; an absent code is worth nothing, which is how
/// the real repository reports a rejected one.
class FakePaymentRepository implements PaymentRepository {
  FakePaymentRepository({
    this.methods = const [cardMethod, instapayMethod, walletMethod],
    this.discounts = const {},
    this.promoThrows = false,
    this.methodsThrow = false,
  });

  final List<PaymentMethodData> methods;
  final Map<String, int> discounts;
  final bool promoThrows;
  final bool methodsThrow;

  @override
  Future<List<PaymentMethodData>> getPaymentMethods() async {
    if (methodsThrow) throw Exception('supabase unreachable');
    return methods;
  }

  @override
  Future<int> validatePromoCode(String code) async {
    if (promoThrows) throw Exception('promo service unreachable');
    return discounts[code] ?? 0;
  }

  @override
  Future<String> uploadReceipt({
    required String bookingOrTripId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) => throw UnimplementedError();

  @override
  Future<CardPaymentSession> createCardPaymentSession({
    required PaymentCheckoutData checkoutData,
    required PaymentMethodData paymentMethod,
    required String bookingId,
    required int amount,
  }) => throw UnimplementedError();

  @override
  Future<CardPaymentState> getCardPaymentState(String bookingId) =>
      throw UnimplementedError();
}

PaymentCubit cubitFor(FakePaymentRepository repository) => PaymentCubit(
  getPaymentMethods: GetPaymentMethodsUseCase(repository),
  applyPromoCode: ApplyPromoCodeUseCase(repository),
);
