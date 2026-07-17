// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';

import 'package:bmt_app/apps/client/features/payments/data/datasources/payment_datasource.dart';
import 'package:bmt_app/apps/client/features/payments/data/datasources/supabase_payment_datasource.dart';
import 'package:bmt_app/apps/client/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:bmt_app/apps/client/features/payments/domain/repositories/payment_repository.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/apply_promo_code_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/create_card_payment_session_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/get_payment_methods_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/upload_payment_receipt_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/cubit/payment_cubit.dart';

/// Registers the payments feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerPaymentDependencies(GetIt getIt) {
  if (!getIt.isRegistered<PaymentDatasource>()) {
    getIt.registerLazySingleton<PaymentDatasource>(
      () => SupabasePaymentDatasource(getIt<SupabaseClient>()),
    );
  }

  if (!getIt.isRegistered<PaymentRepository>()) {
    getIt.registerLazySingleton<PaymentRepository>(
      () => PaymentRepositoryImpl(getIt<PaymentDatasource>()),
    );
  }

  if (!getIt.isRegistered<GetPaymentMethodsUseCase>()) {
    getIt.registerLazySingleton<GetPaymentMethodsUseCase>(
      () => GetPaymentMethodsUseCase(getIt<PaymentRepository>()),
    );
  }

  if (!getIt.isRegistered<UploadPaymentReceiptUseCase>()) {
    getIt.registerLazySingleton<UploadPaymentReceiptUseCase>(
      () => UploadPaymentReceiptUseCase(getIt<PaymentRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateCardPaymentSessionUseCase>()) {
    getIt.registerLazySingleton<CreateCardPaymentSessionUseCase>(
      () => CreateCardPaymentSessionUseCase(getIt<PaymentRepository>()),
    );
  }

  if (!getIt.isRegistered<ApplyPromoCodeUseCase>()) {
    getIt.registerLazySingleton<ApplyPromoCodeUseCase>(
      () => ApplyPromoCodeUseCase(getIt<PaymentRepository>()),
    );
  }

  if (!getIt.isRegistered<PaymentCubit>()) {
    getIt.registerFactory<PaymentCubit>(
      () => PaymentCubit(
        getPaymentMethods: getIt<GetPaymentMethodsUseCase>(),
        applyPromoCode: getIt<ApplyPromoCodeUseCase>(),
      ),
    );
  }
}
