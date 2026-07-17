// GENERATED_PLACEHOLDER_HEADER
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/client/core/storage/remember_me_store.dart';
import 'package:bmt_app/apps/client/features/auth/data/datasources/client_auth_datasource.dart';
import 'package:bmt_app/apps/client/features/auth/data/datasources/mock_auth_datasource.dart';
import 'package:bmt_app/apps/client/features/auth/data/datasources/supabase_client_auth_datasource.dart';
import 'package:bmt_app/apps/client/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bmt_app/apps/client/features/auth/data/repositories/client_auth_repository_impl.dart';
import 'package:bmt_app/apps/client/features/auth/data/repositories/remember_me_repository_impl.dart';
import 'package:bmt_app/apps/client/features/auth/domain/repositories/auth_repository.dart';
import 'package:bmt_app/apps/client/features/auth/domain/repositories/client_auth_repository.dart';
import 'package:bmt_app/apps/client/features/auth/domain/repositories/remember_me_repository.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/clear_remembered_credentials_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/complete_profile_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/get_remembered_credentials_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/save_remembered_credentials_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/domain/usecases/verify_phone_usecase.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/phone_auth_cubit.dart';

/// Registers the auth feature's data sources, repositories, use
/// cases and cubits. Idempotent: safe to call more than once.
void registerAuthDependencies(GetIt getIt) {
  if (!getIt.isRegistered<ClientAuthDatasource>()) {
    getIt.registerLazySingleton<ClientAuthDatasource>(
      () => SupabaseClientAuthDatasource(Supabase.instance.client),
    );
  }

  if (!getIt.isRegistered<ClientAuthRepository>()) {
    getIt.registerLazySingleton<ClientAuthRepository>(
      () => ClientAuthRepositoryImpl(getIt<ClientAuthDatasource>()),
    );
  }

  if (!getIt.isRegistered<SignInWithEmailUseCase>()) {
    getIt.registerLazySingleton<SignInWithEmailUseCase>(
      () => SignInWithEmailUseCase(getIt<ClientAuthRepository>()),
    );
  }

  if (!getIt.isRegistered<SignUpWithEmailUseCase>()) {
    getIt.registerLazySingleton<SignUpWithEmailUseCase>(
      () => SignUpWithEmailUseCase(getIt<ClientAuthRepository>()),
    );
  }

  if (!getIt.isRegistered<SignOutUseCase>()) {
    getIt.registerLazySingleton<SignOutUseCase>(
      () => SignOutUseCase(getIt<ClientAuthRepository>()),
    );
  }

  if (!getIt.isRegistered<RememberMeStore>()) {
    getIt.registerLazySingleton<RememberMeStore>(() => RememberMeStore());
  }

  if (!getIt.isRegistered<RememberMeRepository>()) {
    getIt.registerLazySingleton<RememberMeRepository>(
      () => RememberMeRepositoryImpl(getIt<RememberMeStore>()),
    );
  }

  if (!getIt.isRegistered<SaveRememberedCredentialsUseCase>()) {
    getIt.registerLazySingleton<SaveRememberedCredentialsUseCase>(
      () => SaveRememberedCredentialsUseCase(getIt<RememberMeRepository>()),
    );
  }

  if (!getIt.isRegistered<GetRememberedCredentialsUseCase>()) {
    getIt.registerLazySingleton<GetRememberedCredentialsUseCase>(
      () => GetRememberedCredentialsUseCase(getIt<RememberMeRepository>()),
    );
  }

  if (!getIt.isRegistered<ClearRememberedCredentialsUseCase>()) {
    getIt.registerLazySingleton<ClearRememberedCredentialsUseCase>(
      () => ClearRememberedCredentialsUseCase(getIt<RememberMeRepository>()),
    );
  }

  if (!getIt.isRegistered<ClientAuthCubit>()) {
    getIt.registerFactory<ClientAuthCubit>(
      () => ClientAuthCubit(
        signInWithEmail: getIt<SignInWithEmailUseCase>(),
        signUpWithEmail: getIt<SignUpWithEmailUseCase>(),
        signOut: getIt<SignOutUseCase>(),
        saveRememberedCredentials:
            getIt<SaveRememberedCredentialsUseCase>(),
        getRememberedCredentials:
            getIt<GetRememberedCredentialsUseCase>(),
        clearRememberedCredentials:
            getIt<ClearRememberedCredentialsUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<SendPasswordResetEmailUseCase>()) {
    getIt.registerLazySingleton<SendPasswordResetEmailUseCase>(
      () => SendPasswordResetEmailUseCase(getIt<ClientAuthRepository>()),
    );
  }

  if (!getIt.isRegistered<ForgotPasswordCubit>()) {
    getIt.registerFactory<ForgotPasswordCubit>(
      () => ForgotPasswordCubit(getIt<SendPasswordResetEmailUseCase>()),
    );
  }

  // --- Phone Auth Dependencies (Mock) ---
  if (!getIt.isRegistered<MockAuthDatasource>()) {
    getIt.registerLazySingleton<MockAuthDatasource>(
      () => MockAuthDatasource(),
    );
  }

  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt<MockAuthDatasource>()),
    );
  }

  if (!getIt.isRegistered<VerifyPhoneUseCase>()) {
    getIt.registerLazySingleton<VerifyPhoneUseCase>(
      () => VerifyPhoneUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<VerifyOtpUseCase>()) {
    getIt.registerLazySingleton<VerifyOtpUseCase>(
      () => VerifyOtpUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<CompleteProfileUseCase>()) {
    getIt.registerLazySingleton<CompleteProfileUseCase>(
      () => CompleteProfileUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<PhoneAuthCubit>()) {
    getIt.registerFactory<PhoneAuthCubit>(
      () => PhoneAuthCubit(
        verifyPhoneUseCase: getIt<VerifyPhoneUseCase>(),
        verifyOtpUseCase: getIt<VerifyOtpUseCase>(),
        completeProfileUseCase: getIt<CompleteProfileUseCase>(),
      ),
    );
  }
}
