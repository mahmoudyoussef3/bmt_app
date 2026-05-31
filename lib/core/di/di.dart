import 'package:get_it/get_it.dart';
import 'package:bmt_app/features/driver/data/driver_repository.dart';
import 'package:bmt_app/features/driver/data/mock_driver_repository.dart';
import 'package:bmt_app/features/driver/domain/repositories/driver_repository_interface.dart';
import 'package:bmt_app/features/driver/logic/driver_cubit.dart';
import 'package:bmt_app/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:bmt_app/features/auth/data/mock_auth_repository.dart';
import 'package:bmt_app/features/auth/logic/auth_cubit.dart';
import 'package:bmt_app/core/security/secure_storage.dart';

final GetIt getIt = GetIt.instance;

/// Call this at app start to register core services used across the app.
/// This intentionally uses the existing demo `DriverRepository` wrapped
/// by an adapter so the current `DriverCubit` constructors remain valid.
void setupLocator() {
  // Register the concrete repository (mock wraps the existing demo repository)
  getIt.registerLazySingleton<DriverRepository>(() => MockDriverRepository());

  // Also expose the repository by its interface for future replacements
  getIt.registerLazySingleton<IDriverRepository>(
    () => getIt<DriverRepository>() as MockDriverRepository,
  );

  // Register the cubit using the repository interface so the cubit depends on
  // the abstract `IDriverRepository` moving forward.
  getIt.registerLazySingleton<DriverCubit>(
    () => DriverCubit(getIt<IDriverRepository>()),
  );

  // Secure storage for tokens
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorage());

  // Auth repository and cubit (mock implementations for Phase 1)
  getIt.registerLazySingleton<IAuthRepository>(() => MockAuthRepository());
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(getIt<IAuthRepository>(), getIt<SecureStorage>()),
  );

  // Keep DriverService available for code that already uses it
  // (DriverService will continue to create its own cubit instance).
}
