import 'package:get_it/get_it.dart';
import 'package:bmt_app/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:bmt_app/features/auth/data/mock_auth_repository.dart';
import 'package:bmt_app/features/auth/logic/auth_cubit.dart';
import 'package:bmt_app/core/security/secure_storage.dart';

final GetIt getIt = GetIt.instance;

/// Call this at app start to register shared auth services used by legacy entrypoints.
void setupLocator() {
  // Secure storage for tokens
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorage());

  // Auth repository and cubit (mock implementations for Phase 1)
  getIt.registerLazySingleton<IAuthRepository>(() => MockAuthRepository());
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(getIt<IAuthRepository>(), getIt<SecureStorage>()),
  );
}
